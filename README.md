# Pipeline

Pipeline is a framework & language for crafting massively parallel pipelines. Unlike other languages for defining data flow, Pipeline requires the implementation of components to be written in Python and linked into the Pipeline document. This allows the details of implementations to be separated from the structure of the pipeline.

### An example

As an example, a pipeline for Fizz Buzz could be written as follows -

```python
numbers  from fizzbuzz.numbers
even     from fizzbuzz.even
fizzbuzz from fizzbuzz.fizzbuzz
printer  from fizzbuzz.printer

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
