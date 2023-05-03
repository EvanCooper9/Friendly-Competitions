const firebase_app_id = `1:787056522440:ios:c0fd8dabecf3d15bc121fd`;
const api_secret = `6WVS9HxWRL6kHmOzfiRsGg`;

const demo = module.exports.demo = async function() {
  const response = await fetch(`https://www.google-analytics.com/mp/collect?firebase_app_id=${firebase_app_id}&api_secret=${api_secret}`, {
    method: "POST",
    body: JSON.stringify({
      app_instance_id: '0236C8ACAF824C90A06BAA68A5A63EEC',
      events: [{
        name: 'database_write',
        params: {
          'path': "test_path"
        },
      }]
    })
  });
  console.log(response);
}
