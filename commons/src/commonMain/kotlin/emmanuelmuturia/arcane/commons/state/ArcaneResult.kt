package emmanuelmuturia.arcane.commons.state

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map

sealed class ArcaneResult<out T> {

    data class Success<out T>(val data: T) : ArcaneResult<T>()

    data class Error(val error: String) : ArcaneResult<Nothing>()

}

fun <T> Flow<T>.asResult() : Flow<ArcaneResult<T>> {

    return this.map<T, ArcaneResult<T>> {
        ArcaneResult.Success(data = it)
    }.catch {
        emit(value = ArcaneResult.Error(error = it.message.toString()))
    }

}