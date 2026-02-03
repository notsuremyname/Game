<?php
/**
 * Starlight Merge: Celestial Garden - Ad & Economy API
 */

require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

switch ($action) {
    case 'watch_rewarded':
        handleWatchRewarded();
        break;
    case 'watch_interstitial':
        handleWatchInterstitial();
        break;
    case 'daily_stats':
        handleDailyStats();
        break;
    case 'offerwall_complete':
        handleOfferwallComplete();
        break;
    default:
        errorResponse('Unknown action');
}

/**
 * Handle rewarded video watch
 */
function handleWatchRewarded() {
    $user = requireAuth();
    $userId = $user['id'];
    $data = getJsonBody();
    
    $placement = $data['placement'] ?? 'general';
    $adProvider = $data['provider'] ?? 'unknown';
    
    $db = getDB();
    
    // Check daily cap
    $today = date('Y-m-d');
    $stmt = $db->prepare("SELECT COUNT(*) as count FROM ad_watches WHERE user_id = ? AND ad_type = 'rewarded' AND DATE(watched_at) = ?");
    $stmt->execute([$userId, $today]);
    $watchCount = $stmt->fetch()['count'];
    
    if ($watchCount >= AD_REWARDED_DAILY_CAP) {
        errorResponse('Daily rewarded video limit reached');
    }
    
    // Calculate reward
    $baseMin = AD_REWARDED_MIN_GLIM;
    $baseMax = AD_REWARDED_MAX_GLIM;
    $baseReward = rand($baseMin, $baseMax);
    
    // Apply streak multiplier
    $multiplier = getAdMultiplier($userId);
    $reward = floor($baseReward * $multiplier);
    
    // Placement bonuses
    $placementMultipliers = [
        'offline_double' => 2.0,
        'speed_up' => 1.5,
        'bonus_chest' => 1.8,
        'continue' => 1.2,
        'expedition' => 1.5,
        'event' => 2.0,
        'general' => 1.0
    ];
    
    $placementMult = $placementMultipliers[$placement] ?? 1.0;
    $reward = floor($reward * $placementMult);
    
    // Log ad watch
    $stmt = $db->prepare("INSERT INTO ad_watches (user_id, ad_type, ad_provider, placement, glim_rewarded) VALUES (?, 'rewarded', ?, ?, ?)");
    $stmt->execute([$userId, $adProvider, $placement, $reward]);
    
    // Award Glim
    awardGlim($userId, $reward, 'ad_rewarded', "Rewarded video: {$placement}");
    
    // Update daily ad count
    $stmt = $db->prepare("UPDATE users SET daily_ad_watches = daily_ad_watches + 1 WHERE id = ?");
    $stmt->execute([$userId]);
    
    // Update ad quest progress
    updateQuestProgress($userId, 'ad_watch', 1);
    
    successResponse([
        'watched' => true,
        'glim_rewarded' => $reward,
        'streak_multiplier' => $multiplier,
        'placement_bonus' => $placementMult,
        'daily_watches' => $watchCount + 1,
        'daily_cap' => AD_REWARDED_DAILY_CAP
    ]);
}

/**
 * Handle interstitial watch
 */
function handleWatchInterstitial() {
    $user = requireAuth();
    $userId = $user['id'];
    $data = getJsonBody();
    
    $placement = $data['placement'] ?? 'general';
    $adProvider = $data['provider'] ?? 'unknown';
    
    $db = getDB();
    
    // Small Glim reward for interstitial (optional)
    $reward = rand(10, 30);
    
    // Log ad watch
    $stmt = $db->prepare("INSERT INTO ad_watches (user_id, ad_type, ad_provider, placement, glim_rewarded) VALUES (?, 'interstitial', ?, ?, ?)");
    $stmt->execute([$userId, $adProvider, $placement, $reward]);
    
    // Award small Glim
    awardGlim($userId, $reward, 'ad_interstitial', "Interstitial: {$placement}");
    
    successResponse([
        'watched' => true,
        'glim_rewarded' => $reward
    ]);
}

/**
 * Get daily ad stats
 */
function handleDailyStats() {
    $user = requireAuth();
    $userId = $user['id'];
    
    $db = getDB();
    
    $today = date('Y-m-d');
    
    // Get today's ad watches
    $stmt = $db->prepare("SELECT ad_type, COUNT(*) as count, SUM(glim_rewarded) as total_glim FROM ad_watches WHERE user_id = ? AND DATE(watched_at) = ? GROUP BY ad_type");
    $stmt->execute([$userId, $today]);
    $stats = $stmt->fetchAll();
    
    // Get total Glim from ads today
    $stmt = $db->prepare("SELECT COALESCE(SUM(amount), 0) as total FROM glim_transactions WHERE user_id = ? AND transaction_type LIKE 'ad_%' AND DATE(created_at) = ?");
    $stmt->execute([$userId, $today]);
    $totalAdGlim = $stmt->fetch()['total'];
    
    // Get streak
    $multiplier = getAdMultiplier($userId);
    
    successResponse([
        'today' => $today,
        'ad_stats' => $stats,
        'total_ad_glim' => (int)$totalAdGlim,
        'daily_cap' => DAILY_GLIM_CAP,
        'remaining_cap' => max(0, DAILY_GLIM_CAP - $totalAdGlim),
        'streak_multiplier' => $multiplier,
        'rewarded_cap' => AD_REWARDED_DAILY_CAP,
        'rewarded_watched' => 0
    ]);
}

/**
 * Handle offerwall completion
 */
function handleOfferwallComplete() {
    $user = requireAuth();
    $userId = $user['id'];
    $data = getJsonBody();
    
    $offerId = $data['offer_id'] ?? '';
    $offerValue = $data['offer_value'] ?? 0;
    $provider = $data['provider'] ?? 'unknown';
    
    if (empty($offerId) || $offerValue <= 0) {
        errorResponse('Invalid offer data');
    }
    
    // Verify with offerwall provider (in production)
    // This would include signature verification
    
    // Convert offer value to Glim (offerwall pays more)
    $glimReward = $offerValue * 100; // 1 cent = 100 Glim
    
    // Cap at reasonable amount
    $glimReward = min($glimReward, 50000);
    
    // Award Glim
    awardGlim($userId, $glimReward, 'offerwall', "Offerwall offer: {$offerId}");
    
    successResponse([
        'completed' => true,
        'glim_rewarded' => $glimReward,
        'offer_id' => $offerId
    ]);
}

/**
 * Update quest progress helper
 */
function updateQuestProgress($userId, $questType, $amount) {
    $db = getDB();
    
    $stmt = $db->prepare("SELECT * FROM quests WHERE user_id = ? AND quest_type LIKE ? AND completed = 0");
    $stmt->execute([$userId, "%{$questType}%"]);
    $quests = $stmt->fetchAll();
    
    foreach ($quests as $quest) {
        $newProgress = $quest['progress'] + $amount;
        $completed = $newProgress >= $quest['target'] ? 1 : 0;
        
        $stmt = $db->prepare("UPDATE quests SET progress = ?, completed = ? WHERE id = ?");
        $stmt->execute([min($newProgress, $quest['target']), $completed, $quest['id']]);
    }
}
