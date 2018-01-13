import test from 'ava';
import sinon from 'sinon';
import {EventEmitter} from 'events';
import divided from '../index.js';

test.beforeEach(t => {
    t.context.console_log = console.log;
});
test.afterEach(t => {
    console.log = t.context.console_log;
});

test('divided#calculate returns 2 when the value is 4', t => {
    t.is(divided.calculate(4), 2);
});

test('divided#calculate returns 1 when the value is 3', t => {
    t.is(divided.calculate(3), 1);
});

test('divided#calculate throws exceptions when the value is other than numbers', t => {
    t.throws(divided.calculate);
    t.throws(() => divided.calculate(null), 'Type of numeric is expected.');
    t.throws(() => divided.calculate('abc'), / numeric /);
    t.throws(() => divided.calculate([]), TypeError, /^Type of numeric /);
});

test.serial('divided#read prints "result: 4" when the value is 8 that given from the stdin', t => {
    var ev = new EventEmitter();

    sinon.stub(console, 'log');
    process.openStdin = sinon.stub().returns(ev);
    divided.read();
    ev.emit('data', '8');
    t.true(console.log.calledOnce);
    t.true(console.log.calledWith('result: 4'));
});

test.serial('divided#read prints "Type of numeric is expected." when the value is not a numeric', t => {
    var ev = new EventEmitter();

    sinon.stub(console, 'log');
    process.openStdin = sinon.stub().returns(ev);
    divided.read();
    ev.emit('data', 'abc');
    t.true(console.log.calledOnce);
    t.true(console.log.calledWithMatch('Type of numeric is expected.'));
});
