# MessageBus

## Message Kind

- `Query<TResult>` reads without business mutation.
- `Command<TResult>` expresses an intent to change state.
- `Event<TResult>` is a fact that already happened and can have independent subscribers.

MessageBus is the boundary of an executable use case, not every internal method or value object.

## Synchronous Use Case

In current module code, put the contract in the relevant `Capability/<Scenario>` folder. In legacy feature code this may still be `Orchestration`.

Create a Message with PHPDoc `@implements Command<Result>` or `Query<Result>`. The handler should be a focused executable class with `#[CommandHandler(Message::class)]` or `#[QueryHandler(Message::class)]`:

```php
public function __invoke(
    SaveThingMessage $message,
    MessageContextInterface $context,
): SaveThingResult {
    // business rules + outbound ports
}
```

Use an explicit Result object when the outcome contains multiple fields, success/failure state, or transport-independent errors. A handler must not return an HTTP Response.

Controller/CLI code validates transport input, creates the Message, calls `$this->dispatchMessage($message)`, and presents the Result. Do not call a registered handler directly. `dispatchMessage()` is for a single result; use `publishMessage()` for multicast events.

Inside a handler, use `$context->dispatch($message)` for nested command/query reuse and `$context->publish($event)` for facts. Do not inject handlers directly and do not put the bus inside domain objects.

If the use case reads or writes the DB, depend on a scenario-local port. New SQL adapters should usually use the project Yii DB connection pattern (`YiiDbConnectionFactory`, `ConnectionInterface`, `createCommand()`) unless the local slice already requires legacy Cake ORM.

## Async

Async messages are stable serialized contracts:

- add `#[MessageAlias(Message::ALIAS)]` and an `ALIAS` constant;
- keep payloads serializable as scalars, arrays, or stable normalized values;
- normalize dates to strings such as ATOM;
- do not pass request objects, connections, services, closures, lazy entities, or framework resources;
- treat alias or payload changes as queued contract changes.

Async handlers declare an existing flow and stable binding:

```php
#[CommandHandler(
    ExecuteThingMessage::class,
    flow: MessageRegistryFactory::HEAVY_ASYNC_FLOW,
    primary: false,
    bindingId: 'domain.thing.execute'
)]
```

Choose an existing `ASYNC_FLOW` or `HEAVY_ASYNC_FLOW` by load. A new flow needs an infrastructure reason. Consider retry safety, idempotency, and partial failure.

## Events

Name events in the past tense as facts. Register subscribers with `#[EventSubscriber(...)]`; do not assume they are the only subscriber. Important side effects need safe retry behavior.

## Composite Messages

When one user action intentionally combines existing operations, create an aggregate Message that contains smaller typed contracts or enough typed fields to build them, then dispatch those child messages through `MessageContextInterface`. The composite handler owns orchestration and transaction/context boundaries. It must not flatten unrelated child shapes into a god-object payload and must not inject child handlers directly.

## Verification

- Message kind matches semantics.
- Message contains only use-case input.
- Handler attribute and declared `TResult` agree.
- External dependencies are hidden behind ports.
- SQL/transactions stay in infrastructure adapters, not transport or domain objects.
- Controller only adapts transport.
- Async payload has alias, stable flow/binding, and serializable fields.
- After adding, removing, or renaming a Message/handler/subscriber, compile the registry:

```bash
docker/compose/dev.sh exec -T mvd_cake_php php bin/console message-bus:compile
```

Registry compilation errors, lost bindings, unexpected flow, or unstable `bindingId` block completion.

For sync use cases, cover the handler through fake ports. For HTTP/CLI adapters, check that they dispatch the Message and translate Result/errors correctly. For async alias/payload changes, add or update serialization/registry contract coverage.
