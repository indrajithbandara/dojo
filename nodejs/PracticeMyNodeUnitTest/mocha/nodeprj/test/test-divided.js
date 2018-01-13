var chai = require('chai')
        , should = chai.should();
var divided = require('../lib/divided');
var EventEmitter = require('events').EventEmitter;
require('mocha-sinon');

describe('divided', function() {
    describe('#calculate', function() {
        it('should return 2 when the value is 4', function() {
            divided.calculate(4).should.equal(2);
        });
        it('should return 1 when the value is 3', function() {
            divided.calculate(3).should.equal(1);
        });
        it('should throw exceptions when the value are other than numbers', function() {
            (divided.calculate).should.throw(Error);
            (function() {divided.calculate(null)}).should.throw(Error, 'Type of numeric is expected.');
            (function() {divided.calculate("abc")}).should.throw(Error, / numeric /);
            (function() {divided.calculate([])}).should.throw(Error, /^Type of numeric /);

            //// expect-style sentences are below.
            // var expect = chai.expect;
            // expect(divided.calculate).to.throw(Error);
            // expect(function() {divided.calculate(null)}).to.throw(Error, 'Type of numeric is expected.');
            // expect(function() {divided.calculate("abc")}).to.throw(Error, / numeric /);
            // expect(function() {divided.calculate([])}).to.throw(Error, /^Type of numeric /);
        });
    });

    describe('#read', function() {
        it('should print "result: 4" when the value is 8 that given from the stdin', function(done) {
            var ev = new EventEmitter();
            var _console_log = console.log;
            this.sinon.stub(console, 'log');

            process.openStdin = this.sinon.stub().returns(ev);
            divided.read();
            ev.emit('data', '8');

            console.log.calledOnce.should.be.true;
            console.log.calledWith('result: 4').should.be.true;

            //// expect-style sentences are below.
            //var expect = chai.expect;
            //expect(console.log.calledOnce).to.be.true;
            //expect(console.log.calledWith('result: 4')).to.be.true;

            console.log = _console_log;
            done();
        });
    });
});

