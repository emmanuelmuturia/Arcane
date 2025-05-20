package emmanuelmuturia.arcane

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform