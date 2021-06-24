module Page.SPLAT_ exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob
import Element
import Head
import Head.Seo as Seo
import Html
import List.NonEmpty
import Markdown.Parser
import Markdown.Renderer
import OptimizedDecoder
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    { splat : ( String, List String ) }


page : Page RouteParams Data
page =
    Page.prerenderedRoute
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState { view = view }


routes : DataSource (List RouteParams)
routes =
    content
        |> DataSource.map
            (List.map
                (\contentPage ->
                    { splat = contentPage }
                )
            )


content : DataSource (List ( String, List String ))
content =
    Glob.succeed
        (\leadingPath last ->
            (leadingPath ++ [ last ])
                |> List.NonEmpty.fromList
                |> Maybe.withDefault (List.NonEmpty.singleton last)
        )
        |> Glob.match (Glob.literal "content/")
        |> Glob.capture Glob.recursiveWildcard
        |> Glob.match (Glob.literal "/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toDataSource


data : RouteParams -> DataSource Data
data routeParams =
    case routeParams.splat of
        ( root, parts ) ->
            DataSource.File.bodyWithoutFrontmatter (([ "content", root ] ++ parts |> String.join "/") ++ ".md")
                |> DataSource.andThen
                    (\rawMarkdown ->
                        rawMarkdown
                            |> Markdown.Parser.parse
                            |> Result.mapError (\_ -> "Markdown parsing error")
                            |> Result.andThen (Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer)
                            |> Result.mapError (\_ -> "Markdown parsing error")
                            |> DataSource.fromResult
                    )


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


type alias Data =
    List (Html.Html Never)


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = "TODO"
    , body =
        [ Element.html (Html.div [] static.data)
        ]
    }
