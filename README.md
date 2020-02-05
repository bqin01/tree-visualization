# Tree Visualization
A Simulation Project by Bill Z. Qin

Last Updated on January 09, 2020

<br>

View the current state of the project at [treevis.herokuapp.com](https://treevis.herokuapp.com)!

## What is the Tree Visualization Project?

The Tree Visualization Project is a full-stack application written in Ruby using the [Sinatra Framework](http://sinatrarb.com/). The project uses mathematical and biological models to replicate how trees grow by calculating branches individually and recursively, while also maintaining a holistic view of the tree. Users can sign up and own as many trees as they want.

In its current state, the model of tree growth is rather unpolished and is seemingly random. Stay tuned for algorithm and user-interface improvements!

## How-to Use

### Signing up

Signing up is as simple as it gets. Simply navigate into the Tree View screen from the Home screen and use the top toolbar's "Account" dropdown menu and select "Sign Up". This will produce a pop-up that allows you to select a username and password. Select a unique username and you're ready to go!

Once your account is created, you can login through the same "Account" dropdown menu. Likewise, once you are logged in, there will be a "Logout" option under the "Account" dropdown menu.

### Creating Trees

Once you have an account and are logged in, you will need to create some trees. To do so, simply use the "File" dropdown menu and select "New Tree". This will give you a pop-up that allows you to name your sapling, as well as selecting between making your tree <b>private</b> or <b>public</b>. Private trees will only be viewable and editable by the owner of the tree, while public trees can be viewed by all users and editable by only the owner.

Once your tree is created, it will automatically be tied under your name. To re-navigate to your tree, either keep the URL of the new tree (unique for all trees) and navigate there while logged in, or navigate to the "File" dropdown menu and select "Load Tree", then select the respective tree.

If you no longer want your tree, simply be viewing the tree you want to delete and navigate to the "File" dropdown menu and select "Delete Tree".

### Growing Trees

When you create a tree, you will find it to be an uninteresting sapling. If you want it to grow, simply navigate to the "Update" dropdown meny and select "Go Forward". This will allow you to select a number of days to fast-forward by, anywhere from 1 to 999. After you hit confirm, the application (while taking its time; I'm looking into improving the speed of the algorithm) will replicate and refresh the page, giving you the tree in its new state.

<i><b>Note:</b> Currently, if the tree grows too many branches, it may have issues loading/growing your tree that may cause an Internal Server Error. I am looking to fix this.</i>

## Can I learn more about how these trees grow?

Yes you can! I have created a PDF with big math equations and computer science concepts that you can find [here](https://treevis.herokuapp.com/technical.pdf).
