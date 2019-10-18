#if __VERSION__ < 110
    #extension GL_OES_standard_derivatives : enable
#endif

#if  __VERSION__ > 100 &&__VERSION__ < 130
    #ifdef GL_ES
        #extension GL_EXT_shader_texture_lod : enable
    #else
        #extension GL_ARB_shader_texture_lod : enable

    #endif
#endif

#if __VERSION__ == 100
    #extension GL_EXT_shader_texture_lod : enable
    #extension GL_OES_standard_derivatives : enable
#endif