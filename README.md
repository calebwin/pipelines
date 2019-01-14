![](https://i.imgur.com/ev39mql.png)

Pipeline is a framework & language for crafting massively parallel pipelines. Unlike other languages for defining data flow, Pipeline requires the implementation of components to be written in Python and linked into the Pipeline document. This allows the details of implementations to be separated from the structure of the pipeline.

### An example

As an example, a pipeline for Fizz Buzz could be written as follows -

```python
from fizzbuzz import numbers  as numbers
from fizzbuzz import even     as even
from fizzbuzz import fizzbuzz as fizzbuzz
from fizzbuzz import printer  as printer

numbers
/> even 
|> fizzbuzz where (number=*, fizz="Fizz", buzz="Buzz")
|> printer
```

Meanwhile, the implementation of the components would be written in Python -

```python
def numbers():
    for number in range(1, 100):
        yield number

def even(number):
    return even % 2 == 0

def fizzbuzz(number, fizz, buzz):
    if number % 15 == 0: return fizz + buzz
    elif number % 3 == 0: return fizz
    elif number % 5 == 0: return buzz
    else: return number

def printer(number):
    print(number)
```

Running the Pipeline document would safely execute each component of the pipeline in parallel and output the expected result.

### Some next steps

There are several things I'm hoping to implement in the future for this projects. The highest priority features are robust imports, support for importing other pipelines, support for running pipelines in parrallel from the CLI. I would also like to add an `add` operator for piping data from the stream into multiple components in parallel with the output ending up in the stream in a nondeterministic order. Another thing I think would be quite useful would be support for handling multiple returns from a component. Lastly, I want to implement functionality for persisting data coupled to specific components. Further down the line, I will port the whole thing to C and put in a complete error handling system
