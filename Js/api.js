/**
 * Starlight Merge: Celestial Garden - API Client
 */

const API = {
    baseUrl: 'api/',
    token: localStorage.getItem('starlight_token') || null,

    /**
     * Make API request
     */
    async request(endpoint, options = {}) {
        const url = this.baseUrl + endpoint;
        
        const config = {
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            },
            ...options
        };

        if (this.token) {
            config.headers['Authorization'] = `Bearer ${this.token}`;
        }

        if (config.body && typeof config.body === 'object') {
            config.body = JSON.stringify(config.body);
        }

        try {
            const response = await fetch(url, config);
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.error || 'Request failed');
            }
            
            return data;
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    },

    /**
     * Authentication
     */
    auth: {
        async register(username, email, password) {
            const data = await API.request('auth.php?action=register', {
                method: 'POST',
                body: { username, email, password }
            });
            
            if (data.success && data.token) {
                API.token = data.token;
                localStorage.setItem('starlight_token', data.token);
            }
            
            return data;
        },

        async login(username, password) {
            const data = await API.request('auth.php?action=login', {
                method: 'POST',
                body: { username, password }
            });
            
            if (data.success && data.token) {
                API.token = data.token;
                localStorage.setItem('starlight_token', data.token);
            }
            
            return data;
        },

        async guest() {
            const data = await API.request('auth.php?action=guest', {
                method: 'POST'
            });
            
            if (data.success && data.token) {
                API.token = data.token;
                localStorage.setItem('starlight_token', data.token);
            }
            
            return data;
        },

        async logout() {
            await API.request('auth.php?action=logout', { method: 'POST' });
            API.token = null;
            localStorage.removeItem('starlight_token');
        },

        async me() {
            return await API.request('auth.php?action=me');
        }
    },

    /**
     * Game State
     */
    game: {
        async getState() {
            return await API.request('game.php?action=state');
        },

        async merge(fromIndex, toIndex) {
            return await API.request('game.php?action=merge', {
                method: 'POST',
                body: { from_index: fromIndex, to_index: toIndex }
            });
        },

        async spawn(generatorIndex = 0) {
            return await API.request('game.php?action=spawn', {
                method: 'POST',
                body: { generator_index: generatorIndex }
            });
        },

        async collectOffline(watchAd = false) {
            return await API.request('game.php?action=collect_offline', {
                method: 'POST',
                body: { watch_ad: watchAd }
            });
        },

        async move(fromIndex, toIndex) {
            return await API.request('game.php?action=move', {
                method: 'POST',
                body: { from_index: fromIndex, to_index: toIndex }
            });
        },

        async sell(index) {
            return await API.request('game.php?action=sell', {
                method: 'POST',
                body: { index: index }
            });
        },

        async expand() {
            return await API.request('game.php?action=expand', {
                method: 'POST'
            });
        },

        async prestige() {
            return await API.request('game.php?action=prestige', {
                method: 'POST'
            });
        }
    },

    /**
     * Ads
     */
    ads: {
        async watchRewarded(placement = 'general', provider = 'mock') {
            return await API.request('ads.php?action=watch_rewarded', {
                method: 'POST',
                body: { placement, provider }
            });
        },

        async watchInterstitial(placement = 'general', provider = 'mock') {
            return await API.request('ads.php?action=watch_interstitial', {
                method: 'POST',
                body: { placement, provider }
            });
        },

        async getDailyStats() {
            return await API.request('ads.php?action=daily_stats');
        },

        async offerwallComplete(offerId, offerValue, provider = 'mock') {
            return await API.request('ads.php?action=offerwall_complete', {
                method: 'POST',
                body: { offer_id: offerId, offer_value: offerValue, provider }
            });
        }
    },

    /**
     * Shop
     */
    shop: {
        async getItems() {
            return await API.request('shop.php?action=items');
        },

        async buy(itemId) {
            return await API.request('shop.php?action=buy', {
                method: 'POST',
                body: { item_id: itemId }
            });
        },

        async getRedeemOptions() {
            return await API.request('shop.php?action=redeem_options');
        },

        async requestRedemption(optionId, email) {
            return await API.request('shop.php?action=request_redemption', {
                method: 'POST',
                body: { option_id: optionId, email }
            });
        },

        async getMyRedemptions() {
            return await API.request('shop.php?action=my_redemptions');
        },

        async getPrestigeUpgrades() {
            return await API.request('shop.php?action=prestige_upgrades');
        },

        async buyPrestigeUpgrade(upgradeId) {
            return await API.request('shop.php?action=buy_prestige_upgrade', {
                method: 'POST',
                body: { upgrade_id: upgradeId }
            });
        }
    },

    /**
     * Check if authenticated
     */
    isAuthenticated() {
        return !!this.token;
    },

    /**
     * Clear authentication
     */
    clearAuth() {
        this.token = null;
        localStorage.removeItem('starlight_token');
    }
};

// Export for use in other scripts
window.API = API;
