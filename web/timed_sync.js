self.addEventListener('install', (event) => {
 console.log('installing timed_sync');
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
  console.log('avvio sync');
  sendHourlyNotification();

});

function sendHourlyNotification() {
  console.log('esecuzione temporizzata da timed sync');
  if (Notification.permission === 'granted') {
    console.log('showNotification from timed_sync');
    self.registration.showNotification('TS Quizzy ..notifica', {
      body: 'Ricordati di studiare',
      icon: 'icons/Icon-192.png',
      badge: 'icons/Icon-192.png'
    });
  }else{
    console.log('sendHourlyNotification NOT SENT');
  }
}