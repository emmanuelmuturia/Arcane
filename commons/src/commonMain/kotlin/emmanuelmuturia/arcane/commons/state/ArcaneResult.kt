/*
 * Copyright 2025 Arcane
 *
 * Licenced under the Apache License, Version 2.0 (the "Licence");
 * you may not use this file except in compliance with the Licence.
 * You may obtain a copy of the Licence at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the Licence is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the Licence for the specific language governing permissions and
 * limitations under the Licence.
 */
package emmanuelmuturia.arcane.commons.state

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map

sealed class ArcaneResult<out T> {
    data class Success<out T>(val data: T) : ArcaneResult<T>()

    data class Error(val error: String) : ArcaneResult<Nothing>()
}

fun <T> Flow<T>.asResult(): Flow<ArcaneResult<T>> {
    return this.map<T, ArcaneResult<T>> {
        ArcaneResult.Success(data = it)
    }.catch {
        emit(value = ArcaneResult.Error(error = it.message.toString()))
    }
}