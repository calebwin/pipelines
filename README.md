![](https://i.imgur.com/YfK7YdY.png)
<!--- https://i.imgur.com/rbx2Hlh.png or https://i.imgur.com/YfK7YdY.png) --->
<!--- https://carbon.now.sh/?bg=rgba(239%2C228%2C176%2C1)&t=zenburn&wt=none&l=python&ds=true&dsyoff=20px&dsblur=68px&wc=false&wa=true&pv=56px&ph=56px&ln=false&fm=Ubuntu%20Mono&fs=17px&lh=136%25&si=false&code=from%2520utils%2520import%2520customers%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520as%2520customers%2520%2523%2520a%2520generator%2520function%2520in%2520the%2520utils%2520module%250Afrom%2520utils%2520import%2520parse_row%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520%2520as%2520parser%250Afrom%2520utils%2520import%2520get_recommendations%2520%2520%2520as%2520recommender%250Afrom%2520utils%2520import%2520print_recommendations%2520as%2520printer%250A%250Acustomers%2520%257C%253E%2520parser%2520%257C%253E%2520recommender%2520%257C%253E%2520printer&es=2x&wm=false --->

Pipelines is a language and runtime for crafting massively parallel pipelines. Unlike other languages for defining data flow, the Pipeline language requires implementation of components to be defined seperately in the Python scripting language. This allows the details of implementations to be separated from the structure of the pipeline, while providing access to thousands of active libraries for machine learning, data analysis and processing. Skip to [Getting Started](https://github.com/calebwin/pipelines#some-next-steps) to install the Pipeline compiler.

### An example

As an introductory example, a simple pipeline for Fizz Buzz on even numbers could be written as follows -

```python
from fizzbuzz import numbers
from fizzbuzz import even
from fizzbuzz import fizzbuzz
from fizzbuzz import printer

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
    return number % 2 == 0

def fizzbuzz(number, fizz, buzz):
    if number % 15 == 0: return fizz + buzz
    elif number % 3 == 0: return fizz
    elif number % 5 == 0: return buzz
    else: return number

def printer(number):
    print(number)
```

Running the Pipeline document would safely execute each component of the pipeline in parallel and output the expected result.

### The imports

Components are scripted in Python and linked into a pipeline using imports. The syntax for an import has 3 parts - (1) the path to the module, (2) the name of the function, and (3) the alias for the component. Here's an example -
```python
from parser import parse_fasta as parse
```
That's really all there is to imports. Once a component is imported it can be referenced anywhere in the document with the alias.

### The stream

Every pipeline is operated on a stream of data. The stream of data is created by a Python [generator](https://docs.python.org/3/tutorial/classes.html#generators). The following is an example of a generator that generates a stream of numbers from 0 to 1000.
```python
def numbers():
    for number in range(0, 1000):
        yield number
```
Here's a generator that reads entries from a file
```python
def customers():
    for line in "customers.csv":
        yield line
```
The first component in a pipeline is always the generator. The generator is run in parallel with all other components and each element of data is passed through the other components.
```python
from utils import customers             as customers # a generator function in the utils module
from utils import parse_row             as parser
from utils import get_recommendations   as recommender
from utils import print_recommendations as printer

customers |> parser |> recommender |> printer
```

### The pipes

Pipes are what connect components together to form a pipeline. As of now, there are 2 types of pipes in the Pipeline language - (1) transformer pipes, and (2) filter pipes. Transformer pipes are used when input is to be passed through a component. For example, a function can be defined to determine the potential of a particle and a function can be defined to print the potential.
```python
particles |> get_potential |> printer
```
The above pipeline code would pass data from the stream generated by `particles` through `get_potential` and then the output of `get_potential` through `printer`. Filter pipes work similarly except they use the following component to filter data. For example, a function can be defined to determine if a person is over 50 and then print their names to a file.
```python
population /> over_50 |> printer
```
This would use the function referenced by `over_50` to filter out data from the stream generated by `population` and then pass output to `printer`.

### The `where` keyword

The `where` keyword lets you pass in multiple parameters to a component as opposed to just what the output from the previous component was. For example, a function can be defined to print to a file the names of all applicants under a certain age.
```python
applicants
|> printer where (person=*, age_limit=21)
```
This could be done using a filter as well.
```python
applicants
/> age_limit where (person=*, age=21)
|> printer
```
In this case, the function for `age_limit` could look something like this -
```python
def age_limit(person, age):
    return person.age <= age
```
Note that this function still has just one return value - the boolean expression that is used to determine wether input to the component is passed on as output.

### The `to` keyword
The `to` keyword is for when you want the previous component has multiple return values and you want to specify which ones to pass on to the next component. As an example, if you had a function for calculating the electronegativity and electron affinity of an atom, you could use it in a pipeline as follows -
```python
atoms
|> calculator to (electronegativity, electron_affinity)
|> printer where (line=electronegativity)
```
Here's an example using a filter.
```python
atoms
/> below where (atom=*, limit=2) to (is_below, electronegativity, electron_affinity) with is_below
|> printer where (line=electronegativity)
```
Note the use of the `with` keyword here. This is necessary for filters to specify which return value of the function is used to filter out elements in the stream.

### Getting started
All you need to get started is the Pipelines compiler. You can install it by downloaded the executable from [Releases](https://github.com/calebwin/pipelines/releases).
> If you have the [Nimble](https://github.com/nim-lang/nimble/) package manager installed and `~/.nimble/bin` permanantly added to your PATH environment variable (look this up > if you don't know how to do this), you can also install by running the following command.
> ```
> nimble install pipelines
> ```
Pipelines' only dependancy is [the Python interpreter](https://www.python.org/downloads/release/python-2715/) being installed on your system. At the moment, most versions 2.7 and earlier are supported and support for Python 3 is in the works. Once Pipelines is installed and added to your PATH, you can create a `.pipeline` file, run or compile anywhere on your system -
```console
calebwin@ubuntu:~$ pipelines
the .pipeline compiler (v:0.1.0)

usage:
  pipelines                Show this
  pipelines <file>         Compile .pipeline file
  pipelines <folder>       Compile all .pipeline files in folder
  pipelines run <file>     Run .pipeline file
  pipelines clean <folder> Remove all compiled .py files from folder

for more info, go to github.com/calebwin/pipelines
```

### Some next steps

There are several things I'm hoping to implement in the future for this project. I'm hoping to implement some sort of `and` operator for piping data from the stream into multiple components in parallel with the output ending up in the stream in a nondeterministic order. Further down the line, I plan on porting the whole thing to C and putting in a complete error handling system
