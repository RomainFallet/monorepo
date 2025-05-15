import { strictEqual } from "node:assert";
import { describe, test } from "node:test";
import { helloworld } from "@romainfallet/helloworld";

describe("helloworld", () => {
  test("say hello", () => {
    strictEqual(helloworld(), "Hello World!");
  });
});
