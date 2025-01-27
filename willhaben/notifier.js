

const axios = require('axios');

const TELEGRAM_BOT_TOKEN = '<BOT-TOKEN>'; // Replace with your bot token
const TELEGRAM_CHAT_ID = '<CHAT-ID>'; // Replace with your chat ID

/**
 * Sends a message via Telegram.
 * @param {string} message - The message to send.
 */
function sendTelegramMessage(message) {
    const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;

    axios.post(url, {
        chat_id: TELEGRAM_CHAT_ID,
        text: message,
        parse_mode: 'Markdown', // Optional: Use Markdown for formatting
    })
    .then(response => {
        console.log('Message sent:', response.data.result.text);
    })
    .catch(error => {
        console.error('Error sending message:', error.response ? error.response.data : error.message);
    });
}

/**
 * Notify changes as Telegram messages.
 * @param {Array} changes - Array of change objects.
 */
function notifyChanges(changes) {
    if (changes.length === 0) {
        console.log('No changes to notify.');
        return;
    }

    changes.forEach(change => {
        const message = `
*Price Change Detected*
*Description:* ${change.description}
*Old Price:* my: ${change.my_old_price}, sys: ${change.sys_old_price}
*New Price:* ${change.new_price}
*Reduction:* my: ${change.my_delta_price}, sys: ${change.sys_delta_price}
*Publish Date:* ${change.publish_date}
*End Date:* ${change.end_date}
[View Item](${change.url})
        `.trim();

        sendTelegramMessage(message);
    });
}

module.exports = notifyChanges;
