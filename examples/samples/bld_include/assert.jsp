function pb_assert(val, msg)
{
    if(val) return;
    msg = typeof msg !== 'undefined' ? ': ' + msg : '';
    alert('JavaScript: Assertion Failed' + msg + "\n\n" +
            (new Error()).stack)
}
