package minko;
@:expose("minko.CloneOption")
@:enum abstract CloneOption(Int) from Int to Int {
    var SHALLOW = 0;
    var DEEP = 1;
}
/*
https://www.gamedev.net/forums/topic/686732-using-shadow-gi-lightmaps-in-a-pbr-pipeline/
These days it's common to only bake the indirect contribution from analytical light sources.
This way you can handle the direct lighting with standard deferred or forward rendering,
and apply dynamic shadows using shadow maps or the technique of your choice.
In our engine we expose settings on our lights that let the lighting artist choose whether to only bake indirect lighting, or bake indirect + direct.
For some cases (for instance, where the light only touches static background geometry) they will completely bake the light so that there's no runtime cost.
But for most lights in the foreground they will only bake indirect, and the engine will compute dynamic shadows and diffuse + specular per-pixel.



We also bake shadows for some lights, but we store that in a separate texture.
We'll usually use these for areas that are further away from the camera to save on performance.



In terms of energy conservation and making sure that your baked lighting combines properly with other light sources,
just take the time to think about exactly what you're storing in the light map and make sure you're not "doubling up" on anything.
So if you're just storing indirect diffuse lighting, then adding indirect specular lighting from a cubemap is totally fine.
If you need to, try writing out all of your sources onto a piece of paper and figure out which parts correspond to the rendering equation and your BRDF('s).
This can help for making sure that you have the proper scaling terms (like 1/Pi for a Lambertian BRDF) and also for keeping track of which radiometric quantity is stored in your lightmap.
其实，这是很正常的。



面试，是一个综合考察，不仅仅是硬技能。
成功的人都是相似的，比如，曾经在某件事情上成功过，知道如何把事情做成功。
这是比硬技能更加重要的实力。

大学的时候，学校对大家的定位都是造火箭。
你学过造火箭，我恰好也懂一点造火箭。
一个很合理的考察：你曾经把造火箭这件事情做到了多么精致。



解决问题的能力，很难通过面试准确判断。
智商和反应速度，考察起来要容易很多。
也能近似反应工作中解决问题的能力。

很多公司考算法，最初的目的，也是在这里。
当然，有一些公司错误的解读、模仿算法面试，把他变成了记忆力考试。
公司里，搞研究是成本部门，做业务是利润部门。
大家看到的公司，搞研究的都很少。因为，另外一种搞研究的公司，大多倒闭了。
认为面试的内容，应该基本等价于工作中会用到的最难的技能，这个观点本身是不妥的。
作为面试官，在设计面试流程，甄选面试题的时候，也要大胆的选择造火箭的题目

 */