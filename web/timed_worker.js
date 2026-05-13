self.addEventListener('install', (event) => {
 console.log('installing');
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
  console.log('avvio programmazione da script');
  // Start the hourly loop
  setInterval(() => {
    sendHourlyNotification();
  }, 5000); // 3,600,000 milliseconds = 1 hour
  console.log('setInterval programmato');

});

function sendHourlyNotification() {
  console.log('esecuzione temporizzata');
  if (Notification.permission === 'granted') {
    console.log('eseguo self.registration.showNotification');
    self.registration.showNotification('Hourly Update', {
      body: 'This is your scheduled hourly notification.',
      icon: 'icons/Icon-192.png',
      badge: 'icons/Icon-192.png'
    });
  }else{
  console.log('sendHourlyNotification NOT SENT');
  }
}