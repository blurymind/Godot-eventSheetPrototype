We currently have a visual scripting system similar to blueprints in Unreal - connecting nodes.
The proposal here is for a second visual scripting system, that is similar to event sheets in Construct 2 (proprietary), Multimedia fusion (proprietary) and Gdevelop (open source)
![11](https://user-images.githubusercontent.com/6495061/37964468-81886d54-31b9-11e8-9ba5-555123ad1fc7.jpg)

It is a very different approach from the one with blueprints and people learning to program are still requesting it on facebook and other godot community forums

What is an event sheet visual script in the other engines:
https://www.scirra.com/manual/44/event-sheet-view
The event sheet is pretty much a spreadsheet with two columns - a conditions column and an actions column. Both columns can be populated with logic blocks from nodes and their children that the sheet is attached to (node methods). On the left column the user can only attach conditional methods, on the right - only action methods. This clear divide makes for a very easy to learn way of setting game logic. 
On top of that the user can use expressions in both columns - so potentially use gdscript for more specific instructions. 

Rows can be nested under other rows (called sub-events), can be commented, disabled or re-enabled (just like commenting code) 
https://www.scirra.com/manual/128/sub-events
![subeventexample](https://user-images.githubusercontent.com/6495061/37964565-da595506-31b9-11e8-8d9c-03f7f1944307.png)
Some actions/condition blocks can be negated

Functions that can take parameters can be used as well, by using a special function condition block and nesting conditions/actions under its row
![image28](https://user-images.githubusercontent.com/6495061/37964431-5b118958-31b9-11e8-9a81-2a56ac99c88a.png)
![modifiedcheckmatches](https://user-images.githubusercontent.com/6495061/37964409-4a2fafa2-31b9-11e8-8fee-ac374bb4996a.png)

So What are the advantages over our current visual script:
- It is an alternative style of visual scripting with a big following - a quick look at the number of users of construct 2 and the number of succesful 2d games made with clickteam fusion should be a good enough indicator. It has also been requested on Unity forums too
https://feedback.unity3d.com/suggestions/create-a-visual-scripting-for-begginer-like-construct-2-or-behavior-machine
https://feedback.unity3d.com/suggestions/visual-scripting-based-in-event-sheets-as-construct-2

- It is easier to learn and arguably clearer for non-programmers
- An event sheet can pack much more information of the game logic on one screen than blueprints - less scrolling and panning to get the information. Less wasted empty space between logic blocks. You can technically just take a screenshot of an event sheet and share it to show someone else how to do something.
![6708 image_2e2b4e43](https://user-images.githubusercontent.com/6495061/37964332-fc3ed1a6-31b8-11e8-82d8-835ea0c2ce00.png)

- It is easier to transition learning from event sheets to scripting - because it's more similar to scripting    than blueprints

- Why is it easier to learn than blueprints - the clear divide of condition and action and obvious order of execution. The user gets a filtered list of things to do on the two columns.

- Logic blocks are easy to quickly read/find because they have icons. Most nodes in godot also have icons - they can be reused for the event sheet implementation 

- Less clicks needed to get things working - no need to connect nodes or move nodes on the blueprint table.  You just add or drop logic blocks in the cells. No need to pan at all- you only scroll and its much less.

In any case, I am writing this proposal not to say that one system is better than the other - but more with the hope of sparking interest in developing an alternative to our custom visual scripting approach - an alternative that is popular amongst people learning to code and that is a great transition to gdscript - as I found out from first hand experience 

**Addon progress report 0**

Here is a crude mockup so far:
![capture](https://user-images.githubusercontent.com/6495061/38088809-13d17092-3355-11e8-89b3-563b2015686b.PNG)

Demos of event sheet style systems that you can try online(no log in required):
https://editor.gdevelop-app.com/
https://editor.construct.net/

Event Sheet System Possible Structure:
```
|_Event sheet established variables and connections tab
|_Event sheet script tab
  |_Function(built in or custom)
      |_event sheet row (can be parented to another event sheet row or an event sheet group)
          |_Actions column
               |_Action cell (richtex label) (click to open another window to edit)
          |_ Conditions Column
               |_Condition Cell (richtex label)(click to open another window to edit)
|_Action/Condition Cell Expression Editor
  |_Gdscript editor instance - to be used for expressions
  |_Easy Click interface to access the available subnodes - their nodepaths and methods- clicks bring up menu that populates the expression editor - similar to Clickteam Fusion's
```

Inner workflow:
Event sheet resource can be attached to node -->on runtime it generates a gdscript and that is used by the game

**Addon progress report 1**

I did some work on the addon's most important building block- the event sheet cell

![es-adding](https://user-images.githubusercontent.com/6495061/39065812-e6bc306a-44ca-11e8-9053-c64369d95aee.gif)

Some background in what it does - Basically the event sheet is made out of cells. A cell can contain either conditions (getters/expressions) or actions (setters that can be fed with getters/expressions).
On the GUI side, the event cell is created via a richtextlabel node and bbcode that is generated from gdscript. When you double click on it, the richtextlabel turns into an editbox node containing the actual gdscript expression. 

So an event sheet cell has 2 modes:
- edit mode - textEdit node that can be typed into with gdscript. 
The only difference is that the user does not need to type in If/else/while - that is context sensitive to the parent container as seen in the screenshot. Every line is a new condition, so if the user hasnt started the line with "or" or somethind else, the parser automatically knows that a new line has "and" pretext

When clicked away, switches to view mode.
- view mode - richtext label - When switching to view mode, a bbCode gets parsed from the gdscript that is in edit mode and presented via an interactive richtext label. Apart of being interactive and easy to change , the goal is to present the gdscript code in a clearer way. This means showing the node's name and icon only (not the entire path) and getting rid of some words, when its obvious (such as get_ and set_). Since every clickable part is actually a url tag, when hovering over a node name for example - the user can get some information, such as the full path of the node.
 
About the Add new condition/Action menu:
This is what creates a new gdscript line of code for a condition or an action. Whats great about it is that it lets you easily browse all of the nodes inside a scene and their methods - it sort of works in an inverted way to how autocompletion works in gdscript's editor. It shows all nodes and all of their setter, getter or both methods. You can then narrow down to what you want via a filter. 
If callend from a condition cell, this menu shows only getters, if called from an actions cell, it shows both setter and getter methods.

Note that this is still full of bugs and not even half complete to share, but hopefully makes it clearer what I am proposing

**Progress report 2**
Made some planning on how it can work. Also looked into what needs to be refactored before presenting the concept addon

I made this flowchart to explain how it works at the moment
https://www.draw.io/#Hblurymind%2FGodot-eventSheetPrototype%2Fmaster%2FEventSheetDiagramPlan.xml
![eventsheetmockupplan](https://user-images.githubusercontent.com/6495061/40834668-5c1f4e58-6589-11e8-8e53-ee90d8c36e78.PNG)
Decided to refactor it to generate typed gdscript
 #19264
Its much easier to create bbcode links for further helper menus when its typed 
