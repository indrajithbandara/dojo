/** This is a function return a half of parameter, and round it to zero decimal places. */
exports.calculate = function(num) {
    if (typeof num !== 'number') {
        throw new Error('Type of numeric is expected.');
    }
    return Math.floor(num / 2);
};

/** This is a function return a half of parameter that is read from stdin */
exports.read = function() {
    var stdin = process.openStdin();

    stdin.on('data', function(chunk) {
        var param = parseFloat(chunk);
        try {
            var result = exports.calculate(param);
            console.log('result: ' + result);
        } catch(e) {
            console.log(e);
        }
        process.exit();
    });
};
