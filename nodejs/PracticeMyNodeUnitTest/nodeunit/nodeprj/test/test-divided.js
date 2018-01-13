var divided     = require('../lib/divided');
var events      = require('events');
var nodeunit    = require('nodeunit');

exports['calculate'] = function(test) {
    test.equal(divided.calculate(4), 2);
    test.equal(divided.calculate(3), 1);
    test.throws(function() { divided.calculate(); });
    test.throws(function() { divided.calculate(null); });
    test.throws(function() { divided.calculate("abc"); });
    test.throws(function() { divided.calculate([]); });
    test.done();
};

exports['read'] = nodeunit.testCase({
    setUp: function(callback) {
        // Stores references of any functions.
        this._process_openStdin = process.openStdin;
        this._console_log       = console.log;
        this._divided_calculate = divided.calculate;
        this._process_exit      = process.exit;

        var ev = this.ev = new events.EventEmitter();
        process.openStdin = function() { return ev; };
        callback();
    },
    tearDown: function (callback) {
        // Revert functions when every test cases are finished
        process.opensStdin  = this._process_openStdin;
        process.exit        = this._process_exit;
        divided.calculate   = this._divided_calculate;
        console.log         = this._console_log;
        callback();
    },
    // Testing the value other than a number
    'a value other than a number': function(test) {
        test.expect(1);

        process.exit = test.done;
        divided.calculate = function() {
            throw new Error('Expected a number');
        };
        console.log = function(str) {
            test.equal(str, 'Error: Expected a number');
        };
        divided.read();
        this.ev.emit('data', 'abc');
    },
    // Testing the value that it is a number
    'a number': function(test) {
        test.expect(1);

        process.exit = test.done;
        console.log = function(str) {
            test.equal(str, 'result: 4');
        };
        divided.read();
        this.ev.emit('data', '8');
    }
});
