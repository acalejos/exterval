 Real-valued intervals with support for the `Enumerable` protocol.

  ## Installation

  The package can be installed
  by adding `exterval` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
  [
    {:exterval, "~> 0.2"}
  ]
  end
  ```

  ## Creation

  The entry point for creating an interval is the `~i` sigil:

  ```elixir
  iex> import Exterval
  iex> ~i<(1, 10]>
  (1.0,10.0]
  ```

  Intervals are represented as a struct with the following fields:

  * `left` - the left bracket, either `[` or `(`.
  * `right` - the right bracket, either `]` or `)`.
  * `min` - the lower bound of the interval. Can be `:neg_infinity` or any number.
  * `max` - the upper bound of the interval. Can be `:infinity` or any number.
  * `step` - the step size of the interval. If `nil`, the interval is continuous.

  The minimum value must be less than or equal to the maximum value.

  You may optionally specify a step size. The step size can be any real number.

  ```elixir
  iex> import Exterval
  iex> ~i<[1, 10)//2>
  [1, 10)//2
  iex> ~i<[1, 10)//2> |> Enum.to_list()
  [1.0, 3.0, 5.0, 7.0, 9.0]
  iex> ~i<[1, 10)//2> |> Enum.sum()
  25.0
  iex> ~i<[-1, 3)//-0.5> |> Enum.to_list()
  [2.5, 2.0, 1.5, 1.0, 0.5, 0.0, -0.5, -1.0]
  ```

  You can substitute variables into an interval using string interpolation, since the contents of the interval are just strings.

  ```elixir
  iex> import Exterval
  iex> min = 1
  iex> max = 10
  iex> step = 2
  iex> ~i<[#{min}, #{max})//#{step}>
  [1.0,10.0)//2.0
  ```

  ## Size

  You can use `Enum.count/1` to get the number of elements in the interval.

  If the interval is continuous, or either bound is an infinite bound, returns `:infinity`.
  If a step size is specified, returns the number of elements in the interval, rounded down to the nearest integer.
  If the interval is empty, returns `0`.

  ```elixir
  iex> import Exterval
  iex> ~i<[1, 10]> |> Enum.count()
  :infinity
  iex> ~i<[1, 10)//2> |> Enum.count()
  4
  iex> ~i<[-2,-2]//1.0> |> Enum.count()
  1
  iex> ~i<[1,2]//0.5> |> Enum.count()
  3
  iex> ~i<[-2,-1]//0.75> |> Enum.count()
  2
  ```

  ## Membership

  You can check a values membership in an interval using the normal reserving operator `in` or `Enum.member?/2`.

  ```elixir
  iex> import Exterval
  iex> 1 in ~i<[1, 10]>
  true
  iex> 1 in ~i<[1, 10)//2>
  true
  iex> 3 in ~i<(1, 10)//2>
  true
  ```

  You can also check if an interval is a subset of another interval using `in` or `Enum.member?/2`.

  Sub-interval must satisfy the following to be a subset:

  * The minimum value of the subset must belong to the superset.
  * The maximum value of the subset must belong to the superset.
  * The step size of the subset must be a multiple of the step size of the superset.

  If the superset has no step size, then only the first two conditions must be satisfied.

  if the superset has a step size, and the subset doesn't then membership is `false`.

  ## Enumeration

  You can only enumerate over an interval if it has a step size. You will be able to enumerate over the interval using the `Enumerable` protocol
  and all reduce-powered functions. If you do not specify a step size, the interval will be considered continuous and you will not be able to enumerate over it.
  If either bound is an infinite bound, then you may enumerate indefinitely over the interval, but the size of the interval will be `:infinity` and
  the reduction will never terminate. This may be useful for creating infinite sequences or with.

  If the step size is positive, the interval will be enumerated from the minimum value to the maximum value.
  If the step size is negative, the interval will be enumerated from the maximum value to the minimum value.


  Bear in mind that the more precise the step size, the more elements will be enumerated over even within the same
  upper and lower bounds, and the longer the reduction will take.  Additionally, the more precise the step size, the more
  likely it is that the reduction will not terminate due to floating point precision errors.