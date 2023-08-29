# [prometheus]


[prometheus] is a monitoring system and time-series database


<!-- References below -->
[prometheus]:https://prometheus.io/

#### Tricks and Tips:
Fill in past data for new rules (make sure to backup data before)
- https://jessicagreben.medium.com/prometheus-fill-in-data-for-new-recording-rules-30a14ccb8467

This is a useful tool to check prometheus service discovery and relabeling rules:
https://relabeler.promlabs.com/

###### How to evaluate container CPU usage

```
sum(rate(container_cpu_usage_seconds_total{container_label_com_docker_swarm_service_name="<service_name>"}[1m])) by (name)
```
* rate - [calculate the per-second average rate of how a value is increasing over a period of time](https://www.metricfire.com/blog/understanding-the-prometheus-rate-function/)
* metric `container_cpu_usage_seconds_total` is ever increasing line as name would suggest. With `rate` function we are able to detect (in milliseconds) the CPU usage per second by a container
  * `rate(container_cpu_usage_seconds_total[<time frame>])` metric is finally a necessary proporation. I don't fully understand why but I found a few [proofs](https://stackoverflow.com/questions/34923788/prometheus-convert-cpu-user-seconds-to-cpu-usage) on the internet
  * this is the [best article](https://stackoverflow.com/questions/34923788/prometheus-convert-cpu-user-seconds-to-cpu-usage) I found that explains how to convert this metric to CPU Usage. It is also very helpful to understand the whole query in general
* without sum we will get the usage per every available CPU, e.g. 1ms of cpu1, 2ms of cpu2, and so on, i.e. we have different records for the same container with the only difference in the cpu used. By summing them up, we get total CPU usage across all the CPUs
* `by name` is a grouping by container name. It plays nicely since it automatically summs the usage per every CPU core and output the total CPU usage per container

###### How to evaluate container memory
```
container_memory_usage_bytes{name="<container_name>"}
```
