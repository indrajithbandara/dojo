var redis = require('redis');
var redis_client = redis.createClient(6379, "noderedis");
var listen_port = 10080;

require('http').createServer(function (request, response) {
    redis_client.incr('counter', function(error, reply) {
        response.writeHead(200, {'Content-Type': 'text/plain'});
        response.end("You accessed here " + reply + " times.\n");
    });
}).listen(listen_port, '0.0.0.0');
console.log("Server is running on port " + listen_port + ".");

