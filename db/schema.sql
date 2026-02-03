-- Starlight Merge: Celestial Garden - Database Schema
-- MySQL/MariaDB compatible

-- Create database
CREATE DATABASE IF NOT EXISTS starlight_merge CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE starlight_merge;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(32) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    glim_balance INT DEFAULT 0,
    total_glim_earned INT DEFAULT 0,
    total_glim_redeemed INT DEFAULT 0,
    account_level INT DEFAULT 1,
    account_xp INT DEFAULT 0,
    prestige_level INT DEFAULT 0,
    stardust_balance INT DEFAULT 0,
    login_streak INT DEFAULT 0,
    last_login_date DATE DEFAULT NULL,
    daily_ad_watches INT DEFAULT 0,
    last_ad_reset_date DATE DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    is_banned BOOLEAN DEFAULT FALSE,
    ban_reason VARCHAR(255) DEFAULT NULL,
    INDEX idx_glim_balance (glim_balance),
    INDEX idx_account_level (account_level),
    INDEX idx_prestige (prestige_level)
) ENGINE=InnoDB;

-- User settings/preferences
CREATE TABLE IF NOT EXISTS user_settings (
    user_id INT PRIMARY KEY,
    sound_enabled BOOLEAN DEFAULT TRUE,
    music_enabled BOOLEAN DEFAULT TRUE,
    haptic_enabled BOOLEAN DEFAULT TRUE,
    notifications_enabled BOOLEAN DEFAULT TRUE,
    color_blind_mode VARCHAR(20) DEFAULT 'none',
    high_contrast BOOLEAN DEFAULT FALSE,
    reduced_motion BOOLEAN DEFAULT FALSE,
    font_size VARCHAR(10) DEFAULT 'medium',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Game save state (garden layout)
CREATE TABLE IF NOT EXISTS garden_states (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    biome_id INT DEFAULT 1,
    grid_size INT DEFAULT 4,
    grid_data JSON NOT NULL,
    generators JSON NOT NULL,
    last_offline_calc TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_biome (user_id, biome_id)
) ENGINE=InnoDB;

-- Biomes unlocked by user
CREATE TABLE IF NOT EXISTS unlocked_biomes (
    user_id INT NOT NULL,
    biome_id INT NOT NULL,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, biome_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Creature collection
CREATE TABLE IF NOT EXISTS user_creatures (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    creature_id INT NOT NULL,
    level INT DEFAULT 1,
    xp INT DEFAULT 0,
    is_assigned BOOLEAN DEFAULT FALSE,
    assigned_biome_id INT DEFAULT NULL,
    obtained_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_creature (user_id, creature_id)
) ENGINE=InnoDB;

-- Plant/Item inventory
CREATE TABLE IF NOT EXISTS inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    item_type VARCHAR(50) NOT NULL,
    item_id INT NOT NULL,
    quantity INT DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_item (user_id, item_type, item_id)
) ENGINE=InnoDB;

-- Collection album progress
CREATE TABLE IF NOT EXISTS collection_progress (
    user_id INT NOT NULL,
    category VARCHAR(50) NOT NULL,
    item_id INT NOT NULL,
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, category, item_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Prestige upgrades purchased
CREATE TABLE IF NOT EXISTS prestige_upgrades (
    user_id INT NOT NULL,
    upgrade_type VARCHAR(50) NOT NULL,
    level INT DEFAULT 0,
    total_spent_stardust INT DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, upgrade_type),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Daily login calendar
CREATE TABLE IF NOT EXISTS login_calendar (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    login_date DATE NOT NULL,
    day_number INT NOT NULL,
    reward_claimed BOOLEAN DEFAULT FALSE,
    reward_type VARCHAR(50) DEFAULT NULL,
    reward_amount INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_daily (user_id, login_date)
) ENGINE=InnoDB;

-- Quests and challenges
CREATE TABLE IF NOT EXISTS quests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    quest_type VARCHAR(50) NOT NULL,
    quest_id VARCHAR(50) NOT NULL,
    progress INT DEFAULT 0,
    target INT NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    claimed BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_quests (user_id, completed, claimed)
) ENGINE=InnoDB;

-- Glim transactions (earn/spend history)
CREATE TABLE IF NOT EXISTS glim_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    amount INT NOT NULL,
    balance_after INT NOT NULL,
    description VARCHAR(255),
    related_entity_type VARCHAR(50) DEFAULT NULL,
    related_entity_id INT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_transactions (user_id, created_at),
    INDEX idx_transaction_type (transaction_type)
) ENGINE=InnoDB;

-- Redemption requests
CREATE TABLE IF NOT EXISTS redemption_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    redemption_type VARCHAR(50) NOT NULL,
    glim_amount INT NOT NULL,
    cash_value DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    provider VARCHAR(50) DEFAULT NULL,
    provider_reference VARCHAR(255) DEFAULT NULL,
    processed_at TIMESTAMP DEFAULT NULL,
    processed_by INT DEFAULT NULL,
    rejection_reason VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_status (status),
    INDEX idx_created (created_at)
) ENGINE=InnoDB;

-- Ad watch history
CREATE TABLE IF NOT EXISTS ad_watches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    ad_type VARCHAR(50) NOT NULL,
    ad_provider VARCHAR(50) NOT NULL,
    placement VARCHAR(50) NOT NULL,
    glim_rewarded INT DEFAULT 0,
    watched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_date (user_id, watched_at)
) ENGINE=InnoDB;

-- Achievements
CREATE TABLE IF NOT EXISTS achievements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    achievement_id VARCHAR(50) NOT NULL,
    progress INT DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP DEFAULT NULL,
    claimed BOOLEAN DEFAULT FALSE,
    claimed_at TIMESTAMP DEFAULT NULL,
    PRIMARY KEY (user_id, achievement_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Events participation
CREATE TABLE IF NOT EXISTS event_participation (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    event_id VARCHAR(50) NOT NULL,
    event_data JSON DEFAULT NULL,
    score INT DEFAULT 0,
    rank INT DEFAULT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_event (event_id, score)
) ENGINE=InnoDB;

-- Friends system
CREATE TABLE IF NOT EXISTS friendships (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id_1 INT NOT NULL,
    user_id_2 INT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP DEFAULT NULL,
    UNIQUE KEY unique_friendship (LEAST(user_id_1, user_id_2), GREATEST(user_id_1, user_id_2)),
    FOREIGN KEY (user_id_1) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id_2) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Daily gifts between friends
CREATE TABLE IF NOT EXISTS friend_gifts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    recipient_id INT NOT NULL,
    glim_amount INT DEFAULT 10,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    claimed BOOLEAN DEFAULT FALSE,
    claimed_at TIMESTAMP DEFAULT NULL,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_daily_gift (sender_id, recipient_id, DATE(sent_at))
) ENGINE=InnoDB;

-- Leaderboard snapshots
CREATE TABLE IF NOT EXISTS leaderboard_entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    leaderboard_type VARCHAR(50) NOT NULL,
    period VARCHAR(20) NOT NULL,
    score INT NOT NULL,
    rank INT DEFAULT NULL,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_leaderboard (leaderboard_type, period, score)
) ENGINE=InnoDB;

-- Game configuration (admin editable)
CREATE TABLE IF NOT EXISTS game_config (
    config_key VARCHAR(100) PRIMARY KEY,
    config_value TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by INT DEFAULT NULL
) ENGINE=InnoDB;

-- Insert default game configuration
INSERT INTO game_config (config_key, config_value) VALUES
('glim_per_usd', '10000'),
('daily_glim_cap', '15000'),
('offline_earnings_hours_max', '8'),
('offline_earnings_rate_tier1', '2'),
('offline_earnings_rate_tier2', '5'),
('offline_earnings_rate_tier3', '12'),
('offline_earnings_rate_tier4', '28'),
('offline_earnings_rate_tier5', '65'),
('offline_earnings_rate_tier6', '150'),
('offline_earnings_rate_tier7', '350'),
('ad_rewarded_video_glim_min', '150'),
('ad_rewarded_video_glim_max', '500'),
('ad_interstitial_frequency_minutes', '3'),
('prestige_unlock_level', '100'),
('daily_quest_count', '3'),
('weekly_challenge_count', '2'),
('merge_combo_timeout_seconds', '5'),
('event_duration_days', '7'),
('version', '1.0.0');

-- Plant/Item definitions (static data)
CREATE TABLE IF NOT EXISTS plant_definitions (
    id INT PRIMARY KEY,
    tier INT NOT NULL,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    base_glim_per_minute INT NOT NULL,
    merge_value INT NOT NULL,
    sprite_url VARCHAR(255),
    particle_color VARCHAR(20),
    unlock_biome_id INT DEFAULT 1
) ENGINE=InnoDB;

-- Insert plant definitions
INSERT INTO plant_definitions (id, tier, name, description, base_glim_per_minute, merge_value, particle_color, unlock_biome_id) VALUES
(1, 1, 'Star Sprout', 'A tiny seedling glowing with cosmic potential.', 2, 2, '#FFD700', 1),
(2, 2, 'Moon Bud', 'A luminescent flower that blooms under starlight.', 5, 4, '#C0C0C0', 1),
(3, 3, 'Comet Bloom', 'A flowering plant with petals like trailing comets.', 12, 8, '#00BFFF', 1),
(4, 4, 'Aurora Bush', 'A shimmering bush that shifts colors like the northern lights.', 28, 16, '#00FF7F', 2),
(5, 5, 'Nebula Tree', 'A majestic tree with branches swirling with cosmic mist.', 65, 32, '#FF69B4', 3),
(6, 6, 'Galaxy Ancient', 'A massive entity containing the wisdom of a thousand stars.', 150, 64, '#9370DB', 4),
(7, 7, 'Universal Heart', 'A legendary world-tree that pulses with the rhythm of creation.', 350, 128, '#FFFFFF', 5);

-- Biome definitions
CREATE TABLE IF NOT EXISTS biome_definitions (
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    unlock_level INT NOT NULL,
    unlock_cost_glim INT NOT NULL,
    theme_color VARCHAR(20),
    ambient_sound VARCHAR(50),
    special_mechanic VARCHAR(100)
) ENGINE=InnoDB;

INSERT INTO biome_definitions (id, name, description, unlock_level, unlock_cost_glim, theme_color, ambient_sound, special_mechanic) VALUES
(1, 'Starlight Meadow', 'The default cosmic grassland where all gardens begin.', 1, 0, '#2D1B4E', 'meadow_wind', 'none'),
(2, 'Aurora Forest', 'Trees that glow with the ethereal light of the northern lights.', 15, 5000, '#00E676', 'aurora_hum', 'nighttime_bonus'),
(3, 'Comet Gardens', 'Flowers that bloom when meteors streak across the sky.', 30, 15000, '#00BFFF', 'comet_trails', 'random_showers'),
(4, 'Nebula Marsh', 'Swirling mist wetlands where time moves differently.', 50, 30000, '#E91E63', 'nebula_drone', 'chain_merge_bonus'),
(5, 'Galaxy Peaks', 'Floating mountain islands at the edge of known space.', 75, 50000, '#FFD700', 'cosmic_wind', 'rare_spawns'),
(6, 'Universal Core', 'The central nexus where all cosmic energy converges.', 100, 100000, '#FFFFFF', 'universal_resonance', 'all_bonuses');

-- Achievement definitions
CREATE TABLE IF NOT EXISTS achievement_definitions (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    target_value INT NOT NULL,
    reward_glim INT NOT NULL,
    reward_type VARCHAR(50) DEFAULT 'glim'
) ENGINE=InnoDB;

INSERT INTO achievement_definitions (id, name, description, category, target_value, reward_glim) VALUES
('first_merge', 'First Steps', 'Complete your first merge.', 'tutorial', 1, 100),
('merge_100', 'Merger Apprentice', 'Complete 100 merges.', 'merging', 100, 500),
('merge_1000', 'Merge Master', 'Complete 1,000 merges.', 'merging', 1000, 2000),
('merge_10000', 'Cosmic Gardener', 'Complete 10,000 merges.', 'merging', 10000, 10000),
('tier7_created', 'Creator of Worlds', 'Create your first Universal Heart.', 'collection', 1, 5000),
('tier7_collection', 'World Tree Collector', 'Create 10 Universal Hearts.', 'collection', 10, 25000),
('level_10', 'Rising Star', 'Reach account level 10.', 'progression', 10, 500),
('level_50', 'Celestial Being', 'Reach account level 50.', 'progression', 50, 5000),
('level_100', 'Ascended', 'Reach account level 100.', 'progression', 100, 20000),
('prestige_1', 'First Renewal', 'Complete your first Celestial Renewal.', 'prestige', 1, 10000),
('prestige_5', 'Eternal Cycle', 'Complete 5 Celestial Renewals.', 'prestige', 5, 50000),
('biome_3', 'World Traveler', 'Unlock 3 different biomes.', 'exploration', 3, 2000),
('biome_6', 'Cosmic Explorer', 'Unlock all 6 biomes.', 'exploration', 6, 10000),
('creature_10', 'Creature Friend', 'Collect 10 different creatures.', 'creatures', 10, 1000),
('creature_50', 'Creature Collector', 'Collect 50 different creatures.', 'creatures', 50, 10000),
('login_7', 'Week Warrior', 'Maintain a 7-day login streak.', 'dedication', 7, 1000),
('login_30', 'Monthly Devotee', 'Maintain a 30-day login streak.', 'dedication', 30, 10000),
('glim_10000', 'Glim Hoarder', 'Earn 10,000 Glim total.', 'economy', 10000, 1000),
('glim_100000', 'Glim Tycoon', 'Earn 100,000 Glim total.', 'economy', 100000, 10000),
('glim_1000000', 'Glim Magnate', 'Earn 1,000,000 Glim total.', 'economy', 1000000, 100000),
('ad_watch_10', 'Ad Supporter', 'Watch 10 rewarded video ads.', 'engagement', 10, 500),
('ad_watch_100', 'Ad Enthusiast', 'Watch 100 rewarded video ads.', 'engagement', 100, 5000),
('friend_5', 'Social Gardener', 'Add 5 friends.', 'social', 5, 500),
('friend_20', 'Cosmic Network', 'Add 20 friends.', 'social', 20, 5000);

-- Quest template definitions
CREATE TABLE IF NOT EXISTS quest_templates (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    quest_type VARCHAR(50) NOT NULL,
    target_value INT NOT NULL,
    reward_glim INT NOT NULL,
    difficulty VARCHAR(20) DEFAULT 'easy'
) ENGINE=InnoDB;

INSERT INTO quest_templates (id, name, description, quest_type, target_value, reward_glim, difficulty) VALUES
('daily_merge_50', 'Daily Merger', 'Complete 50 merges today.', 'daily_merge', 50, 100, 'easy'),
('daily_merge_150', 'Merge Marathon', 'Complete 150 merges today.', 'daily_merge', 150, 250, 'medium'),
('daily_merge_300', 'Merge Mania', 'Complete 300 merges today.', 'daily_merge', 300, 500, 'hard'),
('daily_glim_500', 'Glim Gatherer', 'Earn 500 Glim today.', 'daily_earn', 500, 100, 'easy'),
('daily_glim_1500', 'Glim Hunter', 'Earn 1,500 Glim today.', 'daily_earn', 1500, 250, 'medium'),
('daily_glim_5000', 'Glim Master', 'Earn 5,000 Glim today.', 'daily_earn', 5000, 500, 'hard'),
('daily_tier4_3', 'Aurora Maker', 'Create 3 Aurora Bushes today.', 'daily_create', 3, 150, 'medium'),
('daily_tier5_1', 'Nebula Forger', 'Create 1 Nebula Tree today.', 'daily_create', 1, 300, 'hard'),
('daily_creature_2', 'Creature Discoverer', 'Discover 2 new creatures today.', 'daily_creature', 2, 200, 'medium'),
('weekly_merge_2000', 'Weekly Warrior', 'Complete 2,000 merges this week.', 'weekly_merge', 2000, 1000, 'medium'),
('weekly_glim_50000', 'Weekly Wealth', 'Earn 50,000 Glim this week.', 'weekly_earn', 50000, 2000, 'hard'),
('weekly_prestige_1', 'Weekly Renewal', 'Complete 1 Celestial Renewal this week.', 'weekly_prestige', 1, 5000, 'hard');

-- Create admin user (password: admin123 - change in production!)
-- Password hash is for 'admin123' using bcrypt
INSERT INTO users (username, email, password_hash, glim_balance, account_level, is_active) VALUES
('admin', 'admin@starlightmerge.game', '$2y$10$YourHashHere', 999999999, 999, TRUE)
ON DUPLICATE KEY UPDATE username = username;

-- Create indexes for performance
CREATE INDEX idx_users_login ON users(last_login_date);
CREATE INDEX idx_glim_transactions_date ON glim_transactions(created_at);
CREATE INDEX idx_ad_watches_date ON ad_watches(watched_at);
CREATE INDEX idx_quests_expires ON quests(expires_at);
