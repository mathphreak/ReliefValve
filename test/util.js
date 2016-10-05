// Test cases stolen from https://github.com/Reactive-Extensions/RxJS/blob/9d6ea94244c2f40a29373f9ed6b12d951d3f2238/tests/observable/do.js

import test from 'ava';
import Rx from '../src/util/rx';

const TestScheduler = Rx.TestScheduler;
const onNext = Rx.ReactiveTest.onNext;
const onError = Rx.ReactiveTest.onError;
const onCompleted = Rx.ReactiveTest.onCompleted;

function noop() { }

test('doWithArray should see all values', t => {
  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onNext(220, 3),
    onNext(230, 4),
    onNext(240, 5),
    onCompleted(250)
  );

  let i = 0;
  let sum = 2 + 3 + 4 + 5;

  scheduler.startScheduler(() => {
    return xs.doWithArray(a => a.forEach(x => {
      i++;
      sum -= x;
    }));
  });

  t.is(i, 4);
  t.is(sum, 0);
});

test('doWithArray plain action', t => {
  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onNext(220, 3),
    onNext(230, 4),
    onNext(240, 5),
    onCompleted(250)
  );

  let i = 0;
  let j = 0;

  scheduler.startScheduler(() => {
    return xs.doWithArray(arr => {
      i = arr.length;
      j++;
    });
  });

  t.is(i, 4);
  t.is(j, 1);
});

test('doWithArray next completed', t => {
  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onNext(220, 3),
    onNext(230, 4),
    onNext(240, 5),
    onCompleted(250)
  );

  let i = 0;
  let sum = 2 + 3 + 4 + 5;
  let completed = false;

  scheduler.startScheduler(() => {
    return xs.doWithArray(arr => arr.forEach(x => {
      i++;
      sum -= x;
    }), null, () => {
      completed = true;
    });
  });

  t.is(i, 4);
  t.is(sum, 0);
  t.true(completed);
});

test('doWithArray next completed never', t => {
  const scheduler = new TestScheduler();

  let i = 0;
  let completed = false;

  const xs = scheduler.createHotObservable(
    onNext(150, 1)
  );

  scheduler.startScheduler(() => {
    return xs.doWithArray(() => i++, null, () => {
      completed = true;
    });
  });

  t.is(i, 0);
  t.false(completed);
});

test('doWithArray next error', t => {
  const error = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onNext(220, 3),
    onNext(230, 4),
    onNext(240, 5),
    onError(250, error)
  );

  let i = 0;
  let sawError = false;

  scheduler.startScheduler(() => {
    return xs.doWithArray(() => i++, e => {
      sawError = e === error;
    });
  });

  t.is(i, 0);
  t.true(sawError);
});

test('doWithArray next error not', t => {
  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onNext(220, 3),
    onNext(230, 4),
    onNext(240, 5),
    onCompleted(250)
  );

  let i = 0;
  let sum = 2 + 3 + 4 + 5;
  let sawError = false;

  scheduler.startScheduler(() => {
    return xs.doWithArray(arr => arr.forEach(x => {
      i++;
      sum -= x;
    }), () => {
      sawError = true;
    });
  });

  t.is(i, 4);
  t.is(sum, 0);
  t.false(sawError);
});

test('doWithArray next error completed', t => {
  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onNext(220, 3),
    onNext(230, 4),
    onNext(240, 5), onCompleted(250)
  );

  let i = 0;
  let sum = 2 + 3 + 4 + 5;
  let sawError = false;
  let hasCompleted = false;

  scheduler.startScheduler(() => {
    return xs.doWithArray(arr => arr.forEach(x => {
      i++;
      sum -= x;
    }), () => {
      sawError = true;
    }, () => {
      hasCompleted = true;
    });
  });

  t.is(i, 4);
  t.is(sum, 0);
  t.false(sawError);
  t.true(hasCompleted);
});

test('doWithArray next completed error', t => {
  const error = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onNext(220, 3),
    onNext(230, 4),
    onNext(240, 5),
    onError(250, error)
  );

  let i = 0;
  let sawError = false;
  let hasCompleted = false;

  scheduler.startScheduler(() => {
    return xs.doWithArray(() => i++, () => {
      sawError = true;
    }, () => {
      hasCompleted = true;
    });
  });

  t.is(i, 0);
  t.true(sawError);
  t.false(hasCompleted);
});

test('doWithArray next error completed never', t => {
  const scheduler = new TestScheduler();

  let i = 0;
  let sawError = false;
  let hasCompleted = false;

  const xs = scheduler.createHotObservable(
    onNext(150, 1)
  );

  scheduler.startScheduler(() => {
    return xs.doWithArray(() => i++, () => {
      sawError = true;
    }, () => {
      hasCompleted = true;
    });
  });

  t.is(i, 0);
  t.false(sawError);
  t.false(hasCompleted);
});

test('doWithArray observer some data with error', t => {
  const error = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onNext(220, 3),
    onNext(230, 4),
    onNext(240, 5),
    onError(250, error)
  );

  let i = 0;
  let sawError = false;
  let hasCompleted = false;

  scheduler.startScheduler(() => {
    return xs.doWithArray(Rx.Observer.create(() => i++, e => {
      sawError = e === error;
    }, () => {
      hasCompleted = true;
    }));
  });

  t.is(i, 0);
  t.true(sawError);
  t.false(hasCompleted);
});

test('doWithArray next throws', t => {
  const error = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onCompleted(250)
  );

  const results = scheduler.startScheduler(() => {
    return xs.doWithArray(() => {
      throw error;
    });
  });

  t.deepEqual(results.messages[0], onError(250, error));

  t.pass();
});

test('doWithArray next completed next throws', t => {
  const error = new Error();
  const scheduler = new TestScheduler();
  const xs = scheduler.createHotObservable(onNext(150, 1), onNext(210, 2), onCompleted(250));
  const results = scheduler.startScheduler(() => {
    return xs.doWithArray(() => {
      throw error;
    }, null, noop);
  });
  t.deepEqual(results.messages[0], onError(250, error));

  t.pass();
});

test('doWithArray next competed completed throws', t => {
  const error = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onCompleted(250)
  );

  const results = scheduler.startScheduler(() => {
    return xs.doWithArray(noop, null, () => {
      throw error;
    });
  });

  t.deepEqual(results.messages[0], onNext(250, 2));
  t.deepEqual(results.messages[1], onError(250, error));

  t.pass();
});

test('doWithArray next error next throws', t => {
  const error = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onCompleted(250)
  );

  const results = scheduler.startScheduler(() => {
    return xs.doWithArray(() => {
      throw error;
    }, noop);
  });

  t.deepEqual(results.messages[0], onError(250, error));

  t.pass();
});

test('doWithArray next error error throws', t => {
  const error1 = new Error();
  const error2 = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onError(210, error1)
  );

  const results = scheduler.startScheduler(() => {
    return xs.doWithArray(noop, () => {
      throw error2;
    });
  });

  t.deepEqual(results.messages[0], onError(210, error2));

  t.pass();
});

test('doWithArray next error completed next throws', t => {
  const error = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onCompleted(250)
  );

  const results = scheduler.startScheduler(() => {
    return xs.doWithArray(() => {
      throw error;
    }, noop, noop);
  });

  t.deepEqual(results.messages[0], onError(250, error));

  t.pass();
});

test('doWithArray next error completed error throws', t => {
  const error1 = new Error();
  const error2 = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onError(210, error1)
  );

  const results = scheduler.startScheduler(() => {
    return xs.doWithArray(noop, () => {
      throw error2;
    }, noop);
  });

  t.deepEqual(results.messages[0], onError(210, error2));

  t.pass();
});

test('doWithArray next error completed completed throws', t => {
  const error = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onCompleted(250)
  );

  const results = scheduler.startScheduler(() => {
    return xs.doWithArray(noop, noop, () => {
      throw error;
    });
  });

  t.deepEqual(results.messages[0], onNext(250, 2));
  t.deepEqual(results.messages[1], onError(250, error));

  t.pass();
});

test('doWithArray observer next throws', t => {
  const error = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onCompleted(250)
  );

  const results = scheduler.startScheduler(() => {
    return xs.doWithArray(Rx.Observer.create(() => {
      throw error;
    }, noop, noop));
  });

  t.deepEqual(results.messages[0], onError(250, error));

  t.pass();
});

test('doWithArray observer error throws', t => {
  const error1 = new Error();
  const error2 = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onError(210, error1)
  );

  const results = scheduler.startScheduler(() => {
    return xs.doWithArray(Rx.Observer.create(noop, () => {
      throw error2;
    }, noop));
  });

  t.deepEqual(results.messages[0], onError(210, error2));

  t.pass();
});

test('doWithArray observer completed throws', t => {
  const error = new Error();

  const scheduler = new TestScheduler();

  const xs = scheduler.createHotObservable(
    onNext(150, 1),
    onNext(210, 2),
    onCompleted(250)
  );

  const results = scheduler.startScheduler(() => {
    return xs.doWithArray(Rx.Observer.create(noop, noop, () => {
      throw error;
    }));
  });

  t.deepEqual(results.messages[0], onNext(250, 2));
  t.deepEqual(results.messages[1], onError(250, error));

  t.pass();
});
