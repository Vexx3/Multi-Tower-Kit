---

applyTo: '**/*.{luau,lua}'

---

You are an expert Roblox Luau developer. specific instructions for this project. Adhere strictly to the following style, typing, and structure guidelines.

## 1. Code Style & Formatting

* **Indentation:** Use **tabs** for indentation.
* **Casing:**
* **PascalCase:** Services, Class names, Enums, and Roblox APIs.
* **camelCase:** Local variables, function names, member values/methods.
* **LOUD_SNAKE_CASE:** Local constants.


* **Quotes:** Use double quotes `"` for strings. Use single quotes `'` only if the string contains double quotes.
* **Spacing:**
* No vertical alignment of variable assignments.
* Space before and after operators (`x + y`, not `x+y`).
* Space after commas in tables (`{ "a", "b" }`).


* **Blocks:** Do not inline block bodies. Put function bodies and `if` statements on new lines.

## 2. Clean Code Principles

* **Naming:**
* **No Abbreviations:** Use `player` instead of `plr`, `character` instead of `char`.
* **Booleans:** Name as questions (`isEnabled`, `hasLoaded`, `isFirstRun`).
* **Events:** Name to express when they run (`onPlayerAdded`).


* **Structure:**
* **DRY (Don't Repeat Yourself):** Abstract repeated logic into functions or modules.
* **Guard Clauses:** Use early returns to reduce nesting (e.g., `if not valid then return end` instead of wrapping the whole function in an `if`).
* **No Globals:** Avoid `_G` or shared globals; use ModuleScripts for state.



## 3. Type Checking (Luau)

* **Mode:** **DO NOT** add `--!strict` or `--!nonstrict` to the top of files. Assume the environment handles this.
* **Inference:** **DO NOT** add type annotations where Luau can infer them automatically (e.g., `local x = 10` is fine; do not write `local x: number = 10`).
* **Annotations:**
* Annotate function parameters and return types explicitly: `function add(a: number, b: number): number`.
* Use optional types (`?`) for values that can be nil.
* Avoid `any` whenever possible. Use specific types or Generics.


* **New Type Features:** Use Luau's new type solver features (Type Functions) where appropriate for complex types (e.g., generic table transformations).

## 4. Modularization & Dependencies

* **Dependencies:**
* Prefer using existing modules in `Packages/` (e.g., Wally packages) or `ReplicatedStorage/Modules` (e.g., standard utilities like `Dash`).
* If a utility function is needed (like table manipulation), check if `Dash` is available and use it instead of writing a new helper.


* **Ignored Folders:** **DO NOT** modify, refactor, or suggest changes to files inside the following directories:
* `Framework/`
* `Network/`
* `ScriptRepo/`


## 5. Specific Patterns

* **Services:** Always fetch services at the top of the file using `game:GetService("ServiceName")`.
* **ModuleScripts:** Return a table. Do not use `module` (deprecated).
* **Waiting:** Use `task.wait()`, `task.spawn()`, and `task.delay()` instead of global `wait()`, `spawn()`, or `delay()`.