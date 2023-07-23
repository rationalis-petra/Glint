module Glint.Render.Html
  ( render
  , render_doc
  ) where

import Data.Text (Text, pack)
import Text.Blaze.Html5 (Html, html, toHtml, (!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A

import Glint.Syntax

render_doc :: String -> GlintDocument -> Html
render_doc root (GlintDocument {..}) = html $ do
  H.head $ do 
    H.title $ toHtml title
    H.script ! A.src "https://polyfill.io/v3/polyfill.min.js?features=es6" $ pure ()
    H.script
      ! A.id "MathJax-script"
      ! A.src "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"
      $ pure ()
    H.script $ do 
      "MathJax = {processClass : 'math'} "
  H.body ! A.style "position: relative; width: 50%; left: 25%" $ mapM_ (render root) body

render :: String -> GlintDoc -> Html
render = render' 1 . pack

render' :: Int -> Text -> GlintDoc -> Html
render' depth root doc = case doc of 
  Text tp text -> case tp of 
      Regular -> H.span $ toHtml text
      Bold -> H.b $ toHtml text
      Italic -> H.i $ toHtml text
      Monospace -> H.code $ toHtml text

  Title text -> H.h1 $ toHtml text 

  Section title nodes ->
    H.p $ do 
      (header_n depth) (toHtml title)
      mapM_ (render' (depth + 1) root) nodes
  Paragraph nodes -> H.p $ mapM_ (render' depth root) nodes

  List b children -> 
    (if b then H.ol else H.ul) $ do
      let render_child children = 
            H.li $ mapM_ (render' depth root) children
      mapM_ render_child children

  Tag typ children ->  
    H.p $ do
      H.b ! A.style "color: red" $ (toHtml typ)
      mapM_ (render' depth root) children

  Ref link text -> 
    H.a ! A.href (url link) $ toHtml text 
    where 
      url (DocLink txt) = H.textValue $ root <> "/" <> txt <> ".html" 
      url (URLLink txt) = H.textValue $ txt
      
  Definition name children ->
    H.p $ do
      H.b "Definition"
      toHtml (" (" <> name <> "). ")
      mapM_ (render' depth root) children
  Proposition name children -> 
    H.p $ do
      H.b "Proposition"
      toHtml (" (" <> name <> "). ")
      mapM_ (render' depth root) children
  Example mname _ children  -> 
    H.p $ do
      H.b "Example"
      toHtml (maybe ". " (\name -> " (" <> name <> "). ") mname)
      mapM_ (render' depth root) children
  Proof _ children -> 
    H.p $ do
      H.i "Proof"
      mapM_ (render' depth root) children
  InlMath text -> 
    H.span ! A.class_ "math" $ toHtml ("\\(" <> text <> "\\)")
  BlockMath text -> 
    H.p ! A.class_ "math" $ toHtml ("\\[" <> text <> "\\]")

      
  _ -> H.p "unknown doc" 
  

header_n :: Int -> Html -> Html 
header_n n = case n of 
  0 -> H.h1
  1 -> H.h2
  2 -> H.h3
  3 -> H.h4
  4 -> H.h5
  _ -> H.h6
