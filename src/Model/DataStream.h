#pragma once
#include <mutex>
#include <condition_variable>
#include <queue>

#pragma once

template <typename T> class datastream {
  size_t _capacity;
  std::condition_variable _not_full;
  std::condition_variable _not_empty;
  std::mutex _sync;
  std::queue<T> _qu;
  bool _bShutdown = false;

public:
    datastream(size_t capacity) : _capacity(capacity) {
        // empty
    }

    inline void push(const T& _Val) { // insert element at end, provide strong guarantee
        {
          std::unique_lock<std::mutex> lock(_sync);

          while (_qu.size() >= _capacity) {
              _not_full.wait(lock);
          }
         _qu.push(_Val);
        }
        _not_empty.notify_all();
    }

    inline void push(T&& _Val) {
        // insert by moving into element at end, provide strong guarantee
        {
            std::unique_lock<std::mutex> lock(_sync);

            while (_qu.size() >= _capacity) {
                _not_full.wait(lock);
            }
            _qu.push(std::move(_Val));
        }
        _not_empty.notify_all();
    }

  inline void RequestShutdown() {
    {
      std::unique_lock<std::mutex> lock(_sync);
      _bShutdown = true;
    }
    _not_empty.notify_all();
  }

  inline bool pop(T &item) {
    {    std::unique_lock<std::mutex> lock(_sync);


    while (_qu.size() == 0){
        if (_bShutdown) {
          return false;
        }
      else {
        _not_empty.wait(lock);
      }
    }
    item = std::move(_qu.front());
    _qu.pop();
    _not_full.notify_one();
    return true;
  }
}
};