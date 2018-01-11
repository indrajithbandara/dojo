var app = require('express')();

app.get('/', function(req, res) {
    res.send("Hello " + req.query.name + "\n");
});
app.listen(80);

