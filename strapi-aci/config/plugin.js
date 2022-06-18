module.exports = ({ env }) => ({
    upload: {
        config: {
            provider: 'strapi-provider-upload-azure-storage',
            providerOptions: {
                account: env('STORAGE_ACCOUNT'),
                accountKey: env('STORAGE_ACCOUNT_KEY'),
                containerName: env('media'),
                defaultPath: 'assets',
                maxConcurrent: 10
            }
        }
    }
});