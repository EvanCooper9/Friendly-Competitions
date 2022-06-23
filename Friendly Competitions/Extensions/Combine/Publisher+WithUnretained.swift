import Combine

// MARK: - Flat Map Latest

extension Publisher {
    func flatMapLatest<T, O: AnyObject>(withUnretained object: O, _ transform: @escaping (O, Output) -> AnyPublisher<T, Failure>) -> AnyPublisher<T, Failure> {
        flatMapLatest { [weak object] value -> AnyPublisher<T, Failure> in
            guard let object = object else { return .never() }
            return transform(object, value)
        }
        .eraseToAnyPublisher()
    }
}

extension Publisher where Output == Void {
    func flatMapLatest<T, O: AnyObject>(withUnretained object: O, _ transform: @escaping (O) -> AnyPublisher<T, Failure>) -> AnyPublisher<T, Failure> {
        flatMapLatest { [weak object] _ -> AnyPublisher<T, Failure> in
            guard let object = object else { return .never() }
            return transform(object)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Handle Events

extension Publisher {
    func handleEvents<Object: AnyObject>(
        withUnretained object: Object,
        receiveSubscription: ((Object, Subscription) -> Void)? = nil,
        receiveOutput: ((Object, Output) -> Void)? = nil,
        receiveCompletion: ((Object, Subscribers.Completion<Failure>) -> Void)? = nil,
        receiveCancel: ((Object) -> Void)? = nil,
        receiveRequest: ((Object, Subscribers.Demand) -> Void)? = nil
    ) -> Publishers.HandleEvents<Self> {
        handleEvents { [weak object] subscription in
            guard let object = object else { return }
            receiveSubscription?(object, subscription)
        } receiveOutput: { [weak object] output in
            guard let object = object else { return }
            receiveOutput?(object, output)
        } receiveCompletion: { [weak object] completion in
            guard let object = object else { return }
            receiveCompletion?(object, completion)
        } receiveCancel: { [weak object] in
            guard let object = object else { return }
            receiveCancel?(object)
        } receiveRequest: { [weak object] request in
            guard let object = object else { return }
            receiveRequest?(object, request)
        }

    }
}

extension Publisher where Output == Void {
    func handleEvents<Object: AnyObject>(
        withUnretained object: Object,
        receiveSubscription: ((Object, Subscription) -> Void)? = nil,
        receiveOutput: ((Object) -> Void)? = nil,
        receiveCompletion: ((Object, Subscribers.Completion<Failure>) -> Void)? = nil,
        receiveCancel: ((Object) -> Void)? = nil,
        receiveRequest: ((Object, Subscribers.Demand) -> Void)? = nil
    ) -> Publishers.HandleEvents<Self> {
        handleEvents { [weak object] subscription in
            guard let object = object else { return }
            receiveSubscription?(object, subscription)
        } receiveOutput: { [weak object] in
            guard let object = object else { return }
            receiveOutput?(object)
        } receiveCompletion: { [weak object] completion in
            guard let object = object else { return }
            receiveCompletion?(object, completion)
        } receiveCancel: { [weak object] in
            guard let object = object else { return }
            receiveCancel?(object)
        } receiveRequest: { [weak object] request in
            guard let object = object else { return }
            receiveRequest?(object, request)
        }

    }
}

// MARK: - Sink

extension Publisher {
    func sink<O: AnyObject>(withUnretained object: O, receiveCompletion: ((O, Subscribers.Completion<Failure>) -> Void)? = nil, receiveValue: ((O, Output) -> Void)? = nil) -> AnyCancellable {
        sink(receiveCompletion: { [weak object] completion in
            guard let object = object else { return }
            receiveCompletion?(object, completion)
        }, receiveValue: { [weak object] value in
            guard let object = object else { return }
            receiveValue?(object, value)
        })
    }
}
