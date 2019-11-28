ATT&CK Website Docker
=====================

Pre-Requirements
################

* `Docker CE <https://docs.docker.com/install/>`_ : Docker Community Edition (CE) is ideal for developers and small teams looking to get started with Docker and experimenting with container-based apps

Run Docker Image
################

I already build the `image <https://hub.docker.com/repository/docker/cyb3rward0g/attack-website>`_ for you so you just have to run the following:

.. code-block:: console

    $ sudo docker run -it --rm -p 8000:8000 --name attack-website cyb3rward0g/attack-website:0.0.1

    Clean Build            : ---------------------------------------- 0.00s      
    Downloading STIX Data  : ---------------------------------------- 1.48s      
    Initializing Data      : ---------------------------------------- 39.85s      
    Index Page             : ---------------------------------------- 0.42s      
    Group Pages            : ---------------------------------------- 2.99s      
    Software Pages         : ---------------------------------------- 8.49s      
    Technique Pages        : ---------------------------------------- 7.02s      
    Matrix Pages           : ---------------------------------------- 8.64s      
    Tactic Pages           : ---------------------------------------- 0.87s      
    Mitigation Pages       : ---------------------------------------- 0.45s      
    Contribute Page        : ---------------------------------------- 0.12s      
    Resources Page         : ---------------------------------------- 0.00s      
    Redirection Pages      : ---------------------------------------- 0.61s      
    Search Index           : ---------------------------------------- 181.24s      
    Previous Versions      : ---------------------------------------- 10.84s      
    Pelican Content        : ---------------------------------------- Running.../home/attackuser/.local/lib/python3.7/site-packages/scss/selector.py:54: FutureWarning: Possible nested set at position 329
    ''', re.VERBOSE | re.MULTILINE)
    Pelican Content        : ---------------------------------------- 16.87s      

    Running tests:
    ---------------------------------------  -------------------------------------------------------  ------------------------------------------------------- 
    STATUS                                   TEST                                                     MESSAGE                                                 
    ---------------------------------------  -------------------------------------------------------  ------------------------------------------------------- 
    PASSED                                   Output Folder Size                                       Size: 671.90 MB                                         
    PASSED                                   Internal Links                                           5438 OK - 0 broken link(s)                              
    PASSED                                   Unlinked Pages                                           0 unlinked page(s)                                      
    PASSED                                   Relative Links                                           0 page(s) with relative link(s) found                   
    PASSED                                   Broken Citations                                         3308 pages OK, 0 pages broken                           
    ---------------------------------------  -------------------------------------------------------  ------------------------------------------------------- 

    5 tests passed, 0 tests failed

    TOTAL Build Time       : ---------------------------------------- 280.38s      
    TOTAL Test Time        : ---------------------------------------- 11.92s      
    TOTAL Update Time      : ---------------------------------------- 292.30s

You can optionally run it in `detached` mode with the following command:

.. code-block:: console

    $ docker run -d -p 8000:8000 --name attack-website cyb3rward0g/attack-website:0.0.1
    $ docker logs --follow attack-website

Once it is done, open your browser and go to `localhost:8000`

.. image:: _static/docker-attack-website-main.png
    :alt: ATT&CK Website
    :scale: 30%
