---
title: My Netflix Habits
author: Michael Foley
date: '2021-08-29'
slug: my-netflix-habits
categories:
  - Tableau
tags: [MakeoverMonday, Progressive Insurance]
---

Our _Makeover Monday_ developer user group at Progressive Insurance usually picks a topic from the [UK MakeoverMonday](https://www.makeovermonday.co.uk/) to work with, but this month we chose a neat data set from Netflix. You can download your complete viewing history from the Netflix website (instructions [here](https://help.netflix.com/en/node/101917)). (*For some reason, I kept receiving an error message, "We ran into an issue preparing your viewing activity. You can try again now or come back at a later time.", so I painstakingly copied it by hand and stopped at 3 years.*)

My submission, which I posted on [Tableau Public](https://public.tableau.com/views/NetflixViewingHistory_16301571503330/NETFLIXViewing?:language=en-US&publish=yes&:display_count=n&:origin=viz_share_link), doesn't show off much in terms of fancy Tableau chops, but it was a fun exercise. I did get some practice with level-of-detail calcs, and made my first lollipop chart. So what did I discover?

* Wow, I there must have been some 31-day long snowstorm December, 2020. Our bingedex (bing index = % of days watching at least 5 shows) hit 90%.
* COVID hit hard in March 2021 right about the same time as [Heartland](https://www.netflix.com/title/70171946) really gripped our household. This was a dark time for me.
* I expected to see heavier viewing on some days of the week, maybe Friday or Saturday, but that really isn't the case.

<div class='tableauPlaceholder' id='viz1630243235933' style='position: relative'><noscript><a href='#'><img alt='Buh-bummm... ' src='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;Ne&#47;NetflixViewingHistory_16301571503330&#47;NETFLIXViewing&#47;1_rss.png' style='border: none' /></a></noscript><object class='tableauViz'  style='display:none;'><param name='host_url' value='https%3A%2F%2Fpublic.tableau.com%2F' /> <param name='embed_code_version' value='3' /> <param name='site_root' value='' /><param name='name' value='NetflixViewingHistory_16301571503330&#47;NETFLIXViewing' /><param name='tabs' value='no' /><param name='toolbar' value='yes' /><param name='static_image' value='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;Ne&#47;NetflixViewingHistory_16301571503330&#47;NETFLIXViewing&#47;1.png' /> <param name='animate_transition' value='yes' /><param name='display_static_image' value='yes' /><param name='display_spinner' value='yes' /><param name='display_overlay' value='yes' /><param name='display_count' value='yes' /><param name='language' value='en-US' /><param name='filter' value='publish=yes' /></object></div>                <script type='text/javascript'>                    var divElement = document.getElementById('viz1630243235933');                    var vizElement = divElement.getElementsByTagName('object')[0];                    if ( divElement.offsetWidth > 800 ) { vizElement.style.width='1000px';vizElement.style.height='1627px';} else if ( divElement.offsetWidth > 500 ) { vizElement.style.width='1000px';vizElement.style.height='1627px';} else { vizElement.style.width='100%';vizElement.style.height='2327px';}                     var scriptElement = document.createElement('script');                    scriptElement.src = 'https://public.tableau.com/javascripts/api/viz_v1.js';                    vizElement.parentNode.insertBefore(scriptElement, vizElement);                </script>
