package model.rider

import com.jetbrains.rd.generator.nova.Ext
import com.jetbrains.rd.generator.nova.PredefinedType
import com.jetbrains.rd.generator.nova.PredefinedType.string
import com.jetbrains.rd.generator.nova.call
import com.jetbrains.rd.generator.nova.doc
import com.jetbrains.rd.generator.nova.csharp.CSharp50Generator
import com.jetbrains.rd.generator.nova.kotlin.Kotlin11Generator
import com.jetbrains.rd.generator.nova.setting
import com.jetbrains.rider.model.nova.ide.SolutionModel
import model.generated.PluginConstants

@Suppress("unused")
object IdeBrowserModel : Ext(SolutionModel.Solution) {

    init {
        setting(Kotlin11Generator.Namespace, PluginConstants.KOTLIN_MODEL_NAMESPACE)
        setting(CSharp50Generator.Namespace, PluginConstants.CSHARP_MODEL_NAMESPACE)
    }
}
