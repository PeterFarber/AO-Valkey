# AO-Valkey

## Good
- The core of valkey is working and can send commands from lua.

## Bad
- Building the RediJSON module using a wasm target may be impossible as alot of it crates arent supported...
- Another issue is even if we can build the modules we cannot link them dynamically at runtime =(
