# A worked MR description

The conventions are the `writing-mr-descriptions` skill. This is one description that follows them.

> **test: run order transition tests without a database**
>
> The transition tests start a database container for logic that is only a
> status check plus a repository call, so the suite pays for a database it
> doesn't use.
>
> OrderServiceTransitionTest now builds the service from mockk repositories:
>
> - the shared rules are parameterized over every transition and status, with
>   the terminal split derived from Status.isTerminal, so a new status or
>   transition is covered without touching a test body
> - assertions check what the service decides — target status, updatedBy, and
>   that a terminal order is rejected before anything is written — instead of
>   reading the row back
> - updateStatus and findStatusForUpdate move down to OrderRepositoryTest, the
>   only place left exercising that SQL

The why names the concrete waste in this test, not the general principle. Each bullet covers something the diff doesn't
explain on its own: why so few test methods cover so many cases, why the assertions changed shape, why a second file is here.
