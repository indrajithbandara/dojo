'use strict'

exports.calculate = function(num) {
    if (typeof num !== 'number' || isNaN(num)) {
        throw new TypeError('Type of numeric is expected.');
    }
    return Math.floor(num / 2);
};

exports.read = function() {
    var stdin = process.openStdin();
    stdin.on('data', function(chunk) {
        var param = Number(chunk);
        try {
            var result = exports.calculate(param);
            console.log('result: ' + result);
        } catch(e) {
            console.log(e.toString());
        }
    });
};
