const cron                  = require('node-cron');
const AutoRescheduleService = require('../services/AutoRescheduleService');

// Run immediately on startup so we don't have to wait for the first hour tick
(async () => {
  console.log('[AutoReschedule] Initial run on startup...');
  await AutoRescheduleService.run();
})();

// Then run at the top of every hour
cron.schedule('0 * * * *', async () => {
  await AutoRescheduleService.run();
});

console.log('[AutoReschedule] Cron job scheduled — runs every hour.');