# Introducing the md_edit gem

    require 'md_edit'


    s = "# Thoughts

    ## Car

    This will be the car history

    ## Bicycle

    Like a bicycle log.

    ### Brakes

    Front brakes need some work.

    ## Fridge

    When did it last get cleaned out?
    "


    mde = MdEdit.new s
    mde.q 'c' #=> ["car"]
    mde.find 'car'
    # => ["## Car", ["This will be the car history"]] 

    mde.find 'bicycle'

    #=> ["## Bicycle", ["Like a bicycle log.", ["### Brakes", ["Front brakes need some work."]]]] 


The md_edit gem can find a section of a markdown document by its heading. This can be helpful when editing a large document from a web page interface similar to editing a wiki page.


## Resources

* md_edit https://rubygems.org/gems/md_edit

markdown lookup query mdedit md_edit
