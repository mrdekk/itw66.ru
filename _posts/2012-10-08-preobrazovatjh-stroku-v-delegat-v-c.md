---
title: |
    Преобразовать строку в делегат в C#
date: 2012-10-08
authors: [FiloXSee]
tags: [c#, делегат, программирование, компиляция]
categories: [C#]
permalink: /blog/c_sharp/662.html
blogcat: C#
excerpt_separator: <!--cut-->
---

Столкнулся с интересной задачей. У меня есть текст функции, записанный в строку. Я хочу получить из нее делегат и исполнять его, как обычную функцию. Раньше я к этой задаче относится как к чисто теоретической, однако недавно мне понадобилось исполнить строковое выражение и я вспомнил о компиляции кода в реальном времени.

Ну согласитесь, не парсить же текст, не разбивать его на токины и не исполнять же его в ручную? Именно так бы я и сделал когда-то в школе, но сейчас хочется чтобы всю работу делал C#. Зря что ли в него добавляли все эти возможности.

Я не буду рассказывать то как я думал, чтобы дойти до результата, а сразу его представлю. Итак, использование моего класса выглядит следующим образом:

```csharp
// объявляем требуемый делегат. Он может иметь любые принимаемые параметры и возвращаемое значение
public delegate Single    TestDelegate( Single param1, Single param2 );

// строка, в которой записан текст функции. В примере это будет очень простой код. В реальности он может быть любым.
String funcText = "public static Single    FuncName( Single param1, Single param2 )" +
        "{"+
        "    return param1 + param2;"+
        "}";

// Создаем функцию, передавая имя создаваемой функции и строку ее содержащую.
// Кроме того, параметром шаблона передается тип делегата, объявленный ранее
TestDelegate func = DelegateGenerator.CreateDelegate< TestDelegate >( "FuncName", funcText );

// проверяем, получилось ли создать делегат
if ( null == func )
    return;

// работаем как с обычной функцией
Single ss = func( 5, 10 ); // ss = 15
```


Если вам интересно, как же все это работает, то читайте дальше!

<!--cut-->


**Проверяем на ошибки**

На самом деле всю работу делает класс *DelegateGenerator*, который я создал. Он имеет две публичные функции и одну внутреннюю структуру. Функции создания делегата отличаются только возвращаемым значением. Первая функция возвращает сам делегат, а вторая возвращает класс с подробной информацией о созданной функции.

Класс *DelegateInfo< T >* нужен просто для сохранения всей информации о функции и ошибках, которые возникли при ее компиляции.

```csharp
DelegateInfo< T > funcInfo = DelegateGenerator.CreateDelegateInfo< TestDelegate >( "FuncName", funcText );
if( funcInfo.WasError )
    ...; // funcInfo.ErrorText будет содержать текст ошибки компиляции

// исполняем функцию
Single ss = funcInfo.Exec( 5, 10 ); // ss = 15
```

**Детали реализации**

Процесс компиляции функции достаточно прост. Первоначально создается текст класса, куда добавляется наша функция как единственная.

Обратите внимание, что функция, которая будет создаваться должна быть объявлена как **public static**. Это необходимо, чтобы можно было корректно исполнять эту функцию из любого кода. Помним, что свободных функций в C# не существует.

После того, как получен текст нового класса его нужно скомпилировать. При компиляции указываются все библиотеки, от которых будет зависеть создаваемая функция (переменная *referenceAssemblies*).

```csharp
String[] referenceAssemblies = 
{ 
    "System.dll",
    "System.Data.dll",
    "System.Design.dll",
    "System.Drawing.dll",
    "System.Windows.Forms.dll",
    "System.Xml.dll"
};
```

Если ваша функция будет зависеть от каких-то библиотек, то расширьте их список. Если у вас слишком большое разнообразие подключаемых библиотек или вы не можете их знать заранее, то передавайте его при создании функции, как еще один параметр.

После компиляции класса проверяем, были ли ошибки компиляции. Если они были, то формируем строку с ними и выходим. Если все прошло успешно, то получаем функцию у скомпилированного класса и возвращаем ее как требуемый делегат.


**Полный код класса**

```csharp
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Reflection;

using Microsoft.CSharp;
using System.CodeDom.Compiler;

namespace DelegateGenerator
{
    public class DelegateGenerator
    {
        #region static variables
        // статическая переменная для создания уникальных имен
        private static Int32            m_classIndex = 0;
        #endregion


        #region internal types
        /// <summary>
        /// класс, который содержит всю информацию о делегате
        /// </summary>
        public class DelegateInfo< T >
        {
            // исходный код функции
            public String            Code{ get; set; }
            // информация о созданной функции
            public MethodInfo        MethodInfo{ get; set; }
            // скомпелированный делегат
            public Delegate            Delegate{ get; set; }
            public T            Exec{ get{ return (T)Convert.ChangeType( this.Delegate, typeof(T) ); } }
            // текст ошибки
            public String            ErrorText{ get; set; }
            // была ли ошибка компиляции
            public bool            WasError{ get{ return !String.IsNullOrEmpty( this.ErrorText ); } }
        }
        #endregion


        #region management
        /// <summary>
        /// Создаем делегат по коду
        /// </summary>
        /// <typeparam name="T">тип делегата</typeparam>
        /// <param name="name">Имя создаваемой функции. Должно быть таким же, как в тексте функции</param>
        /// <param name="code">Текст функции</param>
        public static T        CreateDelegate< T >( String funcName, String code )
        {
            // заполняем информацию о функции
            DelegateInfo< T > del = new DelegateInfo< T >();
            del.Code        = code;
            del.MethodInfo    = null;
            del.Delegate    = null;
            del.ErrorText    = String.Empty;

            // компилируем функцию
            CompileDelegate< T >( funcName, del );
            if( !del.WasError )
                return (T)Convert.ChangeType( del.Delegate, typeof(T) );
            return default( T );
        }


        /// <summary>
        /// Создаем делегат по коду и возвращаем структуру с информацией о нем
        /// </summary>
        /// <typeparam name="T">тип делегата</typeparam>
        /// <param name="name">Имя создаваемой функции. Должно быть таким же, как в тексте функции</param>
        /// <param name="code">Текст функции</param>
        public static DelegateInfo< T >    CreateDelegateInfo< T >( String funcName, String code )
        {
            // заполняем информацию о функции
            DelegateInfo< T > del = new DelegateInfo< T >();
            del.Code        = code;
            del.MethodInfo    = null;
            del.Delegate    = null;
            del.ErrorText    = String.Empty;

            // компилируем функцию
            CompileDelegate< T >( funcName, del );
            return del;
        }
        #endregion


        #region compile functions
        /// <summary>
        /// Компилируем делегат
        /// </summary>
        private static void    CompileDelegate< T >( String name, DelegateInfo< T > del )
        {
            // перечисляем все библиотеки, от которых может зависеть текст функции
            String[] referenceAssemblies = 
            { 
                "System.dll",
                "System.Data.dll",
                "System.Design.dll",
                "System.Drawing.dll",
                "System.Windows.Forms.dll",
                "System.Xml.dll"
            };

            String className = "C" + name + m_classIndex.ToString();
            m_classIndex++;

            // создаем полный текст класса с функцией
            StringBuilder sb = new StringBuilder();
            sb.AppendLine( "using System;" );
            sb.AppendLine( "using System.Data;" );
            sb.AppendLine( "using System.Text;" );
            sb.AppendLine( "using System.Design;" );
            sb.AppendLine( "using System.Drawing;" );
            sb.AppendLine( "using System.Windows.Forms;" );
            sb.AppendLine( "using System.Collections.Generic;" );
            sb.AppendLine( "namespace DelegateGenerator" );
            sb.AppendLine( "{" );
            sb.Append( "    public class " ); sb.AppendLine( className );
            sb.AppendLine( "    {" );
            sb.AppendLine( del.Code );
            sb.AppendLine( "    }" );
            sb.AppendLine( "}" );

            // компилируем класс
            CompilerParameters codeParams = new CompilerParameters( referenceAssemblies );
            codeParams.GenerateExecutable = false;
            codeParams.GenerateInMemory = true;
            CSharpCodeProvider codeProvider = new CSharpCodeProvider( );
            CompilerResults codeResult = codeProvider.CompileAssemblyFromSource( codeParams, sb.ToString() );

            // проверяем результат на ошибку
            if( codeResult.Errors.HasErrors )
            {
                StringBuilder err = new StringBuilder();
                for ( int i = 0; i < codeResult.Errors.Count; ++i )
                    err.AppendLine( codeResult.Errors[ i ].ToString() );
                del.ErrorText = err.ToString();
                return;
            }

            // получаем функцию созданного класса по имени
            Type type = codeResult.CompiledAssembly.GetType( "DelegateGenerator." + className );
            del.MethodInfo = type.GetMethod( name );
            if( null == del.MethodInfo )
            {
                del.ErrorText = String.Format( "Delegate name '{0}' error", name );
            }
            else
            {
                del.Delegate = Delegate.CreateDelegate( typeof( T ), del.MethodInfo );
                if( null == del.Delegate )
                    del.ErrorText = String.Format( "Delegate type '{0}' error", name );
            }
        }
        }
        #endregion
    }
}
```


Из текста для краткости я вырезал обработку исключений и проверки многопоточности. Они не нужны для демонстрации возможностей. И помните, что компиляция - это затратная по времени операция. У меня компиляция простой функции занимала около 0.14 секунды. Я не ставил целью данной статьи исследовать реализацию на производительность, так что если вам это интересно, то попробуйте сами.

### Комментарии

> **mrdekk, 9 окт. 2012, 01:54**
С помощью этих идей можно делать интересные вещи:
>
>- Систему плагинов для приложения
>- Генератор отчетов
>- Классы-обертки для PropertyGrid
>- ...
>
>Однако обязательно стоит помнить, что такие вещи открывают не только проблемы производительности, но и проблемы безопасности. Т.к. из этого компилируемого кода можно много чего узнать о Вашем приложении с помощью рефлексии. <br/>
>
>И еще, функции не обязательно должны быть public static — это важно для темы статьи, т.к. мы хотим получить делегат. Однако если не ставить целью получить именно делегат, можно компилировать целые классы и выполнять их на лету.

>> **FiloXSee, 9 окт. 2012, 11:39**
>> Да. Еще хочу добавить задачи, которые можно решать таким методов:<br/>
1. Вычисление строковых выражений<br/>
2. Создание скриптовых функций

> **FiloXSee, 9 окт. 2012, 12:09**
> На форумах подсказали, что есть еще реализация от Microsoft похожей задачи. Она более функциональна, но и более тяжеловесна. Кому интересно, читайте про <a href="http://msdn.microsoft.com/en-us/library/system.codedom.compiler.codedomprovider.aspx" rel="nofollow">CodeDomProvider</a>.
