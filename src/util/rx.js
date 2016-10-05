import Rx from 'rx';

Rx.Observable.prototype.doWithArray = function (observerOrOnNext, onError, onCompleted) {
  return this.toArray().do(observerOrOnNext, onError, onCompleted).flatMap(x => x);
};

export default Rx;
