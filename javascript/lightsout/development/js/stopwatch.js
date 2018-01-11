/*
Copyright (c) 2010-2015 Giulia Alfonsi <electric.g@gmail.com>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/

function StopWatch() {
  var myself = this;
  var timeElement;
  var clocktimer;

  var startAt = 0;  // Time of last start / resume. (0 if not running)
  var lapTime = 0;  // Time on the clock when last stopped in milliseconds

  var now = function() {
    return (new Date()).getTime(); 
  };

  // Reset
  this.reset = function() {
    lapTime = startAt = 0;
  };

  // Duration
  this.time = function() {
    return lapTime + (startAt ? now() - startAt : 0); 
  };

  this.pad = function(num, size) {
    var s = "0000" + num;
    return s.substr(s.length - size);
  }

  this.formatTime = function(time) {
    var h = m = s = ms = 0;
    var newTime = '';

    h = Math.floor( time / (60 * 60 * 1000) );
    time = time % (60 * 60 * 1000);
    m = Math.floor( time / (60 * 1000) );
    time = time % (60 * 1000);
    s = Math.floor( time / 1000 );
    ms = time % 1000;

    newTime = myself.pad(h, 2) + ':' + myself.pad(m, 2)
                  + ':' + myself.pad(s, 2) + ':' + myself.pad(ms, 3);
    return newTime;
  }

  arguments.callee.update = function() {
    timeElement.innerHTML = myself.formatTime(myself.time());
  }

  this.show = function() {
    timeElement = document.getElementById('time');
    StopWatch.update();
  }

  this.start = function() {
    clocktimer = setInterval("StopWatch.update()", 1);
    startAt = startAt ? startAt : now();
  }

  this.stop = function() {
    // If running, update elapsed time otherwise keep it
    lapTime = startAt ? lapTime + now() - startAt : lapTime;
    startAt = 0;

    clearInterval(clocktimer);
  }

  this.reset = function() {
    myself.stop();
    myself.reset();
    myself.update();
  }
}

