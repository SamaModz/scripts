require("child_process").exec("node -e 'console.log(1)'", (e, stdout) => {
  if (e) throw e;
  console.log(stdout);
});
console.log(2);
// Output:
// 2
// 1
// Explanation:
// The `exec` function is asynchronous, so the callback that logs `1` is executed after the current event loop tick, allowing `console.log(2)` to execute first.  This demonstrates the non-blocking nature of Node.js.
