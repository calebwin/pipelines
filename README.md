# Pipeline

Pipeline is a framework & language for crafting massively parallel pipelines. Unlike other languages for defining data flow, Pipeline requires the implementation of components to be written in Python and linked into the Pipeline document. This allows the details of implementations to be separated from the structure of the pipeline.

### An example

As an example, a pipeline for Fizz Buzz could be written as follows -

```
generator from fizzbuzz/generator
fizzbuzz  from fizzbuzz/fizzbuzz
printer   from fizzbuzz/printer

generator | fizzbuzz | printer
```

Meanwhile, the implementation of the components would be written in Python -

```python
def generator():
    for number in range(1, 100):
        yield number
def fizzbuzz(number):
    if number % 15 == 0: return "FizzBuzz"
    elif number % 3 == 0: return "Fizz"
    elif number % 5 == 0: return "Buzz"
    else: return number
def printer(number):
    print(number)
```

Running the Pipeline document would safely execute each component of the pipeline in parallel and output the expected result.
