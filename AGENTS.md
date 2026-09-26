## AutoIt function headers and UDF development

- Before writing or reviewing an AutoIt function header, check `UDF-spec.md`, especially **Functions → Headers** and **Internal use only**. The source page is marked as a work in progress; where it differs from the repository-specific rules below, follow these rules.
- Use a `; #FUNCTION#` block for public functions and a `; #INTERNAL_USE_ONLY#` block for helper functions. Keep the standard field layout used in this repository: `Name`, `Description`, `Syntax`, `Parameters`, `Return values`, `Author`, `Modified`, `Remarks`, `Related`, `Link`, `Example`.
- Keep `Description` concise. In `Parameters`, explain the meaning of arguments, default values, and `ByRef` where these affect use of the function. The header must match the actual signature and execution paths.
- Use `Modified` to name people who helped modify the function. Do not put dates, change descriptions, or version history there.
- In `Return values`, describe the actual values returned on success and failure. Where the function makes this distinction, use `On Success - ...` and `On Failure - ... and sets @error ...`. Do not force this split on functions that merely preserve a received `@error` or return a Boolean without setting their own error state.
- Document `@error` codes in that function's `Return values`, not in `Remarks` or in a combined list under another function. A single code may appear on one line; list multiple codes on separate lines with their meanings. Include only codes that the function actually sets or propagates.
- If a function propagates `@error` and `@extended` from another function, say so in `Return values` and identify the source. Explain `@extended` when it carries information useful to the caller. Do not assign a helper function's error codes meanings they do not have in the public function.
- Use `Remarks` for behavior, limitations, and the meaning of states—for example, whether COM accepting a command confirms that a document was actually displayed. Do not move lists of `@error` codes there.

Example for a function with several error codes:

```autoit
; Return values .: On Success - 1.
;                  On Failure - 0 and sets @error to one of the following:
;                    1 = Invalid input.
;                    2 = Unavailable GUI.
;                    3 = Operation failed.
;                  @extended contains the underlying error when available.
```
