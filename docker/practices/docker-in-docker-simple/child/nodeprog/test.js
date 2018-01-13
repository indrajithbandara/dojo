var http = require("http");

console.log("#######################################################");
console.log("# Starting http server ...                            #");
console.log("#######################################################");

http.createServer(function (request, response) {
    var ip = request.headers['x-forwarded-for'] || request.connection.remoteAddress;
    console.log("Received a request from " + ip);
    response.writeHead(200, {"Content-Type": "text/plain"});
    response.end("This is a test response.\n");
}).listen(80, "0.0.0.0");

