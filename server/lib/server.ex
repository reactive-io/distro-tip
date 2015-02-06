require Logger

defmodule Server do
  @name :stack

  def start do
    pid = spawn __MODULE__, :loop, [HashDict.new, []]
    :global.register_name(@name, pid)
  end

  def loop(subs, stack) do
    receive do
      {:subscribe, name, pid} ->
        Logger.info("#{name} subscribed")
        loop(HashDict.put(subs, name, pid), stack)
      {:unsubscribe, name} ->
        Logger.info("#{name} unsubscribed")
        loop(HashDict.delete(subs, name), stack)
      {:push, name, item} ->
        Logger.info("#{name} gave: '#{item}'")
        notify(:push, subs, name, item)
        loop(subs, [{name, item} | stack])
      {:pop, name} ->
        if length(stack) == 0 do
          Logger.info("whoops, stack is empty")
          send(HashDict.get(subs, name), {:notify, :empty})
          loop(subs, [])
        else
          head = {from, item} = hd(stack)
          Logger.info("#{name} took: '#{item}'")
          notify(:pop, subs, name, head)
          loop(subs, tl(stack))
        end
      {:get, name} ->
        Logger.info("#{name} requested stack")
        send HashDict.get(subs, name), {:notify, :get, stack}
        loop(subs, stack)
      _any ->
        loop(subs, stack)
    end
  end

  defp notify(action, subs, name, item) do
    for {_name, pid} <- subs do
      send pid, {:notify, action, name, item}
    end
  end
end
