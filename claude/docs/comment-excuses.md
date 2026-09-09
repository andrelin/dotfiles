# The excuses for keeping a comment

The rule and the cut-down pass are the `cutting-comments` skill.
Read this only when a comment is being argued for — each row is the argument, and what is actually true.

| Excuse | Reality |
| --- | --- |
| "This one explains a real subtlety." | Then put it in the code. Try the rename or the extracted function; keep the comment only if neither works. |
| "The next reader won't have the context I have." | They'll have the code, the tests and the history. They won't have a comment that stayed true. |
| "It's only two lines." | Two lines that no test covers and no compiler checks. Cost is paid at every future read. |
| "The author asked for it in review." | A separate conversation. It doesn't make the comment true a year from now. |
| "I'll leave it — removing it isn't my change." | Expanding a wildcard import isn't your change either, and that one you do. Same reasoning. |
