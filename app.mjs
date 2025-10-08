import http from 'http';

http.get('http://example.com', (res) => {
  let data = '';

  // A chunk of data has been received.
  res.on('data', (chunk) => {
    data += chunk;
  });

  // The whole response has been received. Print out the result.
  res.on('end', () => {
    console.log(data);
  });

}).on('error', (err) => {
    console.error('Error: ' + err.message);
  });

// To run this code, save it in a file named app.mjs and execute it using Node.js with the command: node app.mjs
// Make sure you have Node.js installed on your system.


