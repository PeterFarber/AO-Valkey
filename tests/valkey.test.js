const {describe, it} = require("node:test");
const assert = require("assert");
const fs = require("fs");
const wasm = fs.readFileSync("./process.wasm");
const m = require(__dirname + "/process.js");

describe("Physics Tests", async () => {
  var instance;
  const handle = async function (msg, env) {
    const res = await instance.cwrap("handle", "string", ["string", "string"], {
      async: true,
    })(JSON.stringify(msg), JSON.stringify(env));
    console.log("Memory used:", instance.HEAP8.length);
    return JSON.parse(res);
  };

  it("Create instance", async () => {
    console.log("Creating instance...");
    var instantiateWasm = function (imports, cb) {
      WebAssembly.instantiate(wasm, imports).then((result) =>
        cb(result.instance)
      );
      return {};
    };

    instance = await m({
      mode: "test",
      blockHeight: 100,
      spawn: {
        Scheduler: "TEST_SCHED_ADDR",
      },
      Process: {
        Id: "AOS",
        Owner: "FOOBAR",
      },
      instantiateWasm,
    });
    await new Promise((r) => setTimeout(r, 1000));
    console.log("Instance created.");
    await new Promise((r) => setTimeout(r, 250));

    assert.ok(instance);
  });

  it("Valkey", async () => {

    const result = await handle(getEval(`
        local valkey = require('valkey')
        valkey.create()
        print(valkey.send('SET FOO bar'))
        print(valkey.send('GET FOO'))
        return "OK"
        `), getEnv());
    console.log(result);
    assert.ok(true)
  });

});

function getEval(expr) {
  return {
    Target: "AOS",
    From: "FOOBAR",
    Owner: "FOOBAR",

    Module: "FOO",
    Id: "1",

    "Block-Height": "1000",
    Timestamp: Date.now(),
    Tags: [{name: "Action", value: "Eval"}],
    Data: expr,
  };
}

function getEnv() {
  return {
    Process: {
      Id: "AOS",
      Owner: "FOOBAR",

      Tags: [{name: "Name", value: "TEST_PROCESS_OWNER"}],
    },
  };
}